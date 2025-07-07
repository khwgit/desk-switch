#include "kvm_helper_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

#include <memory>
#include <sstream>
#include <thread>
#include <atomic>
#include <mutex>
#include <set>
#include <string>
#include <vector>

namespace kvm_helper
{

  namespace
  {
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> input_sink;
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> monitor_sink;

    HHOOK keyboard_hook = nullptr;
    HHOOK mouse_hook = nullptr;
    std::thread hook_thread;
    std::atomic<bool> running{false};
    std::mutex hook_mutex;

    // Input blocking state
    std::set<std::string> blocked_input_types;
    std::mutex blocked_input_mutex;

    std::atomic<bool> cursor_hidden{false};

    // Set of allowed input types for filtering
    std::set<std::string> allowed_input_types;
    std::mutex allowed_input_mutex;

    // Monitor detection
    HWND monitor_hwnd = nullptr;
    WNDPROC original_wndproc = nullptr;

    LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
    {
      if (nCode == HC_ACTION && input_sink)
      {
        KBDLLHOOKSTRUCT *p = (KBDLLHOOKSTRUCT *)lParam;

        // Check if keyboard input is allowed
        {
          std::lock_guard<std::mutex> lock(allowed_input_mutex);
          if (!allowed_input_types.empty() && allowed_input_types.find("keyboard") == allowed_input_types.end())
          {
            // Keyboard input is not in the allowed types, skip it
            return CallNextHookEx(nullptr, nCode, wParam, lParam);
          }
        }

        // Always capture the event first, regardless of blocking state
        flutter::EncodableMap event;
        event[flutter::EncodableValue("kind")] = flutter::EncodableValue("keyboard");
        event[flutter::EncodableValue("code")] = flutter::EncodableValue((int)p->vkCode);
        event[flutter::EncodableValue("type")] = flutter::EncodableValue(
            wParam == WM_KEYDOWN ? "keyDown" : wParam == WM_KEYUP    ? "keyUp"
                                           : wParam == WM_SYSKEYDOWN ? "keyDown"
                                           : wParam == WM_SYSKEYUP   ? "keyUp"
                                                                     : "unknown");
        // Handle modifiers
        std::vector<flutter::EncodableValue> modifiers;
        if (GetAsyncKeyState(VK_SHIFT) & 0x8000)
          modifiers.emplace_back("shift");
        if (GetAsyncKeyState(VK_CONTROL) & 0x8000)
          modifiers.emplace_back("control");
        if (GetAsyncKeyState(VK_MENU) & 0x8000)
          modifiers.emplace_back("option");
        if (GetAsyncKeyState(VK_LWIN) & 0x8000 || GetAsyncKeyState(VK_RWIN) & 0x8000)
          modifiers.emplace_back("command");
        event[flutter::EncodableValue("modifiers")] = flutter::EncodableValue(modifiers);
        event[flutter::EncodableValue("character")] = flutter::EncodableValue(); // Not available
        event[flutter::EncodableValue("timestamp")] = flutter::EncodableValue((int)p->time);

        // Send the event to Dart side
        input_sink->Success(flutter::EncodableValue(event));

        // Check if keyboard input is blocked - if so, prevent it from reaching other applications
        {
          std::lock_guard<std::mutex> lock(blocked_input_mutex);
          if (blocked_input_types.find("keyboard") != blocked_input_types.end())
          {
            return 1; // Block the input from reaching other applications
          }
        }
      }
      return CallNextHookEx(nullptr, nCode, wParam, lParam);
    }

    LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam)
    {
      if (nCode == HC_ACTION && input_sink)
      {
        MSLLHOOKSTRUCT *p = (MSLLHOOKSTRUCT *)lParam;

        // Check if mouse input is allowed
        {
          std::lock_guard<std::mutex> lock(allowed_input_mutex);
          if (!allowed_input_types.empty() && allowed_input_types.find("mouse") == allowed_input_types.end())
          {
            // Mouse input is not in the allowed types, skip it
            return CallNextHookEx(nullptr, nCode, wParam, lParam);
          }
        }

        // Always capture the event first, regardless of blocking state
        flutter::EncodableMap event;
        event[flutter::EncodableValue("kind")] = flutter::EncodableValue("mouse");
        event[flutter::EncodableValue("x")] = flutter::EncodableValue((double)p->pt.x);
        event[flutter::EncodableValue("y")] = flutter::EncodableValue((double)p->pt.y);
        event[flutter::EncodableValue("timestamp")] = flutter::EncodableValue((int)p->time);
        std::string type;
        std::string button = "left";
        int clickCount = 1;
        double deltaX = 0, deltaY = 0, deltaZ = 0;
        switch (wParam)
        {
        case WM_LBUTTONDOWN:
          type = "leftMouseDown";
          break;
        case WM_LBUTTONUP:
          type = "leftMouseUp";
          break;
        case WM_RBUTTONDOWN:
          type = "rightMouseDown";
          button = "right";
          break;
        case WM_RBUTTONUP:
          type = "rightMouseUp";
          button = "right";
          break;
        case WM_MOUSEMOVE:
          type = "mouseMoved";
          break;
        case WM_MOUSEWHEEL:
          type = "scrollWheel";
          deltaY = GET_WHEEL_DELTA_WPARAM(p->mouseData);
          break;
        case WM_MBUTTONDOWN:
          type = "otherMouseDown";
          button = "center";
          break;
        case WM_MBUTTONUP:
          type = "otherMouseUp";
          button = "center";
          break;
        case WM_MBUTTONDBLCLK:
          type = "otherMouseDown";
          button = "center";
          clickCount = 2;
          break;
        case WM_LBUTTONDBLCLK:
          type = "leftMouseDown";
          clickCount = 2;
          break;
        case WM_RBUTTONDBLCLK:
          type = "rightMouseDown";
          button = "right";
          clickCount = 2;
          break;
        default:
          type = "unknown";
          break;
        }
        event[flutter::EncodableValue("type")] = flutter::EncodableValue(type);
        event[flutter::EncodableValue("button")] = flutter::EncodableValue(button);
        event[flutter::EncodableValue("clickCount")] = flutter::EncodableValue(clickCount);
        event[flutter::EncodableValue("deltaX")] = flutter::EncodableValue(deltaX);
        event[flutter::EncodableValue("deltaY")] = flutter::EncodableValue(deltaY);
        event[flutter::EncodableValue("deltaZ")] = flutter::EncodableValue(deltaZ);

        // Send the event to Dart side
        input_sink->Success(flutter::EncodableValue(event));

        // Check if mouse input is blocked - if so, prevent it from reaching other applications
        {
          std::lock_guard<std::mutex> lock(blocked_input_mutex);
          if (blocked_input_types.find("mouse") != blocked_input_types.end())
          {
            return 1; // Block the input from reaching other applications
          }
        }
      }
      return CallNextHookEx(nullptr, nCode, wParam, lParam);
    }

    void HookThreadProc()
    {
      keyboard_hook = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, nullptr, 0);
      mouse_hook = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, nullptr, 0);
      MSG msg;
      running = true;
      while (running && GetMessage(&msg, nullptr, 0, 0))
      {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      }
      if (keyboard_hook)
        UnhookWindowsHookEx(keyboard_hook);
      if (mouse_hook)
        UnhookWindowsHookEx(mouse_hook);
    }

    void StartHooks()
    {
      std::lock_guard<std::mutex> lock(hook_mutex);
      if (!running)
      {
        running = true;
        hook_thread = std::thread(HookThreadProc);
      }
    }

    void StopHooks()
    {
      std::lock_guard<std::mutex> lock(hook_mutex);
      if (running)
      {
        running = false;
        PostThreadMessage(GetThreadId(hook_thread.native_handle()), WM_QUIT, 0, 0);
        if (hook_thread.joinable())
          hook_thread.join();
      }
    }

  } // namespace

  // static
  void KvmHelperPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "kvm_helper",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<KvmHelperPlugin>();

    // Single input event channel
    auto input_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        registrar->messenger(), "kvm_helper/inputs",
        &flutter::StandardMethodCodec::GetInstance());
    auto input_handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [](const flutter::EncodableValue *arguments,
           std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
        {
          input_sink = std::move(events);

          // Parse the types parameter if provided
          if (arguments && std::holds_alternative<flutter::EncodableMap>(*arguments))
          {
            const auto &args = std::get<flutter::EncodableMap>(*arguments);
            if (args.count(flutter::EncodableValue("types")))
            {
              const auto &types = std::get<std::vector<flutter::EncodableValue>>(args.at(flutter::EncodableValue("types")));
              std::lock_guard<std::mutex> lock(allowed_input_mutex);
              allowed_input_types.clear();
              for (const auto &type : types)
              {
                if (std::holds_alternative<std::string>(type))
                {
                  allowed_input_types.insert(std::get<std::string>(type));
                }
              }
            }
          }

          StartHooks();
          return nullptr;
        },
        [](const flutter::EncodableValue *arguments)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
        {
          input_sink.reset();
          StopHooks();
          return nullptr;
        });
    input_channel->SetStreamHandler(std::move(input_handler));

    // Monitor event channel
    auto monitor_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        registrar->messenger(), "kvm_helper/monitors",
        &flutter::StandardMethodCodec::GetInstance());

    auto monitor_handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [](const flutter::EncodableValue *arguments,
           std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
        {
          monitor_sink = std::move(events);
          // Send initial monitor list
          SendMonitorList();
          return nullptr;
        },
        [](const flutter::EncodableValue *arguments)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
        {
          monitor_sink.reset();
          return nullptr;
        });
    monitor_channel->SetStreamHandler(std::move(monitor_handler));

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  KvmHelperPlugin::KvmHelperPlugin() {}

  KvmHelperPlugin::~KvmHelperPlugin()
  {
    StopHooks();
  }

  void KvmHelperPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    if (method_call.method_name().compare("requestPermission") == 0)
    {
      // On Windows, we don't need explicit permission for input capture/injection
      // The hooks will work as long as the application has appropriate privileges
      result->Success(true);
    }
    else if (method_call.method_name().compare("isPermissionGranted") == 0)
    {
      // On Windows, permissions are typically granted by default for desktop applications
      result->Success(true);
    }
    else if (method_call.method_name().compare("injectMouseInput") == 0)
    {
      // Improved mouse injection logic
      if (method_call.arguments() && std::holds_alternative<flutter::EncodableMap>(*method_call.arguments()))
      {
        const auto &args = std::get<flutter::EncodableMap>(*method_call.arguments());
        double x = 0, y = 0;
        std::string type;
        if (args.count(flutter::EncodableValue("x")))
          x = std::get<double>(args.at(flutter::EncodableValue("x")));
        if (args.count(flutter::EncodableValue("y")))
          y = std::get<double>(args.at(flutter::EncodableValue("y")));
        if (args.count(flutter::EncodableValue("type")))
          type = std::get<std::string>(args.at(flutter::EncodableValue("type")));

        INPUT input = {0};
        input.type = INPUT_MOUSE;

        // Convert to absolute coordinates
        LONG absX = static_cast<LONG>(x * 65535.0 / (GetSystemMetrics(SM_CXSCREEN) - 1));
        LONG absY = static_cast<LONG>(y * 65535.0 / (GetSystemMetrics(SM_CYSCREEN) - 1));

        if (type == "leftMouseDown" || type == "leftMouseUp" ||
            type == "rightMouseDown" || type == "rightMouseUp" ||
            type == "mouseMoved")
        {
          input.mi.dx = absX;
          input.mi.dy = absY;
          input.mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
          if (type == "leftMouseDown")
            input.mi.dwFlags |= MOUSEEVENTF_LEFTDOWN;
          if (type == "leftMouseUp")
            input.mi.dwFlags |= MOUSEEVENTF_LEFTUP;
          if (type == "rightMouseDown")
            input.mi.dwFlags |= MOUSEEVENTF_RIGHTDOWN;
          if (type == "rightMouseUp")
            input.mi.dwFlags |= MOUSEEVENTF_RIGHTUP;
          SendInput(1, &input, sizeof(INPUT));
        }
        else if (type == "scrollWheel")
        {
          input.mi.dwFlags = MOUSEEVENTF_WHEEL;
          if (args.count(flutter::EncodableValue("deltaY")))
            input.mi.mouseData = static_cast<DWORD>(std::get<double>(args.at(flutter::EncodableValue("deltaY"))));
          SendInput(1, &input, sizeof(INPUT));
        }
        // Add more cases as needed
        result->Success();
      }
      else
      {
        result->Error("INVALID_ARGUMENTS", "Invalid mouse event arguments");
      }
    }
    else if (method_call.method_name().compare("injectKeyboardInput") == 0)
    {
      // Parse arguments and call SendInput for keyboard
      if (method_call.arguments() && std::holds_alternative<flutter::EncodableMap>(*method_call.arguments()))
      {
        const auto &args = std::get<flutter::EncodableMap>(*method_call.arguments());
        int code = 0;
        std::string type;
        std::vector<std::string> modifiers;
        if (args.count(flutter::EncodableValue("code")))
          code = std::get<int>(args.at(flutter::EncodableValue("code")));
        if (args.count(flutter::EncodableValue("type")))
          type = std::get<std::string>(args.at(flutter::EncodableValue("type")));
        if (args.count(flutter::EncodableValue("modifiers")))
        {
          const auto &mods = std::get<std::vector<flutter::EncodableValue>>(args.at(flutter::EncodableValue("modifiers")));
          for (const auto &mod : mods)
          {
            if (std::holds_alternative<std::string>(mod))
              modifiers.push_back(std::get<std::string>(mod));
          }
        }
        // Press modifier keys down if needed
        std::vector<INPUT> inputs;
        auto add_modifier = [&](WORD vk)
        {
          INPUT mod_input = {0};
          mod_input.type = INPUT_KEYBOARD;
          mod_input.ki.wVk = vk;
          mod_input.ki.dwFlags = 0;
          inputs.push_back(mod_input);
        };
        for (const auto &mod : modifiers)
        {
          if (mod == "shift")
            add_modifier(VK_SHIFT);
          else if (mod == "control")
            add_modifier(VK_CONTROL);
          else if (mod == "option")
            add_modifier(VK_MENU);
          else if (mod == "command")
            add_modifier(VK_LWIN); // Only left win for simplicity
        }
        // Main key event
        INPUT input = {0};
        input.type = INPUT_KEYBOARD;
        input.ki.wVk = static_cast<WORD>(code);
        if (type == "keyUp")
          input.ki.dwFlags = KEYEVENTF_KEYUP;
        inputs.push_back(input);
        // Release modifier keys if needed
        auto add_modifier_up = [&](WORD vk)
        {
          INPUT mod_input = {0};
          mod_input.type = INPUT_KEYBOARD;
          mod_input.ki.wVk = vk;
          mod_input.ki.dwFlags = KEYEVENTF_KEYUP;
          inputs.push_back(mod_input);
        };
        for (const auto &mod : modifiers)
        {
          if (mod == "shift")
            add_modifier_up(VK_SHIFT);
          else if (mod == "control")
            add_modifier_up(VK_CONTROL);
          else if (mod == "option")
            add_modifier_up(VK_MENU);
          else if (mod == "command")
            add_modifier_up(VK_LWIN);
        }
        SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
        result->Success();
      }
      else
      {
        result->Error("INVALID_ARGUMENTS", "Invalid keyboard event arguments");
      }
    }
    else if (method_call.method_name().compare("setInputBlocked") == 0)
    {
      if (method_call.arguments() && std::holds_alternative<flutter::EncodableMap>(*method_call.arguments()))
      {
        const auto &args = std::get<flutter::EncodableMap>(*method_call.arguments());
        bool blocked = false;
        if (args.count(flutter::EncodableValue("blocked")))
          blocked = std::get<bool>(args.at(flutter::EncodableValue("blocked")));

        std::lock_guard<std::mutex> lock(blocked_input_mutex);
        bool mouse_should_be_blocked = false;

        if (args.count(flutter::EncodableValue("types")))
        {
          const auto &types = std::get<std::vector<flutter::EncodableValue>>(args.at(flutter::EncodableValue("types")));
          for (const auto &type : types)
          {
            if (std::holds_alternative<std::string>(type))
            {
              std::string typeStr = std::get<std::string>(type);
              if (blocked)
                blocked_input_types.insert(typeStr);
              else
                blocked_input_types.erase(typeStr);
            }
          }
        }
        else
        {
          // Block/unblock all inputs
          if (blocked)
          {
            blocked_input_types.insert("keyboard");
            blocked_input_types.insert("mouse");
          }
          else
          {
            blocked_input_types.clear();
          }
        }

        mouse_should_be_blocked = blocked_input_types.find("mouse") != blocked_input_types.end();
        // Hide or show cursor as needed
        if (mouse_should_be_blocked && !cursor_hidden)
        {
          while (ShowCursor(FALSE) >= 0)
          {
          }
          cursor_hidden = true;
        }
        else if (!mouse_should_be_blocked && cursor_hidden)
        {
          while (ShowCursor(TRUE) < 0)
          {
          }
          cursor_hidden = false;
        }
        result->Success(true);
      }
      else
      {
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for setInputBlocked");
      }
    }
    else if (method_call.method_name().compare("getBlockedInputs") == 0)
    {
      std::lock_guard<std::mutex> lock(blocked_input_mutex);
      std::vector<flutter::EncodableValue> blocked_types;
      for (const auto &type : blocked_input_types)
      {
        blocked_types.emplace_back(type);
      }
      result->Success(flutter::EncodableValue(blocked_types));
    }
    else
    {
      result->NotImplemented();
    }

    // Monitor helper functions
    void SendMonitorList()
    {
      if (!monitor_sink)
        return;

      std::vector<flutter::EncodableValue> monitors;

      // Enumerate all monitors
      EnumDisplayMonitors(nullptr, nullptr, [](HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) -> BOOL
                          {
          auto monitors_ptr = reinterpret_cast<std::vector<flutter::EncodableValue>*>(dwData);
          
          MONITORINFOEX monitorInfo;
          monitorInfo.cbSize = sizeof(MONITORINFOEX);
          if (GetMonitorInfo(hMonitor, &monitorInfo))
          {
            flutter::EncodableMap monitor;
            monitor[flutter::EncodableValue("id")] = flutter::EncodableValue(monitorInfo.szDevice);
            monitor[flutter::EncodableValue("name")] = flutter::EncodableValue(monitorInfo.szDevice);
            monitor[flutter::EncodableValue("x")] = flutter::EncodableValue((double)monitorInfo.rcMonitor.left);
            monitor[flutter::EncodableValue("y")] = flutter::EncodableValue((double)monitorInfo.rcMonitor.top);
            monitor[flutter::EncodableValue("width")] = flutter::EncodableValue((double)(monitorInfo.rcMonitor.right - monitorInfo.rcMonitor.left));
            monitor[flutter::EncodableValue("height")] = flutter::EncodableValue((double)(monitorInfo.rcMonitor.bottom - monitorInfo.rcMonitor.top));
            monitor[flutter::EncodableValue("isPrimary")] = flutter::EncodableValue((monitorInfo.dwFlags & MONITORINFOF_PRIMARY) != 0);
            monitor[flutter::EncodableValue("scaleFactor")] = flutter::EncodableValue(1.0); // Default scale factor
            
            monitors_ptr->emplace_back(flutter::EncodableValue(monitor));
          }
          return TRUE; }, reinterpret_cast<LPARAM>(&monitors));

      monitor_sink->Success(flutter::EncodableValue(monitors));
    }

    // Window procedure to handle monitor changes
    LRESULT CALLBACK MonitorWndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
    {
      if (uMsg == WM_DISPLAYCHANGE)
      {
        // Monitor configuration changed, send updated list
        SendMonitorList();
      }
      return CallWindowProc(original_wndproc, hwnd, uMsg, wParam, lParam);
    }
  }

} // namespace kvm_helper
