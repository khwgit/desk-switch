#ifndef FLUTTER_PLUGIN_KVM_HELPER_PLUGIN_H_
#define FLUTTER_PLUGIN_KVM_HELPER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <set>
#include <string>

namespace kvm_helper
{

    class KvmHelperPlugin : public flutter::Plugin
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

        KvmHelperPlugin(flutter::PluginRegistrarWindows *registrar);

        virtual ~KvmHelperPlugin();

        // Disallow copy and assign.
        KvmHelperPlugin(const KvmHelperPlugin &) = delete;
        KvmHelperPlugin &operator=(const KvmHelperPlugin &) = delete;

        void StartMonitorDetection();
        void StopMonitorDetection();

        void StartInputDetection();
        void StopInputDetection();

        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    private:
        std::unique_ptr<flutter::PluginRegistrarWindows> registrar;
    };

} // namespace kvm_helper

#endif // FLUTTER_PLUGIN_KVM_HELPER_PLUGIN_H_
