import Cocoa
import FlutterMacOS
import CoreGraphics
import ApplicationServices
import IOKit

enum InputType: String, CaseIterable {
  case keyboard = "keyboard"
  case mouse = "mouse"
}

public class KvmHelperPlugin: NSObject, FlutterPlugin {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var blockedInputTypes: Set<InputType> = []
  private var inputSink: FlutterEventSink?
  private var monitorSink: FlutterEventSink?
  private var originalCursor: NSCursor?
  private var allowedInputTypes: Set<InputType> = Set(InputType.allCases) // Default to all types
  private var monitorNotificationPort: IONotificationPortRef?
  private var monitorIterator: io_iterator_t = 0
  private var screenParametersObserver: NSObjectProtocol?
  private var customEventSource: CGEventSource? = CGEventSource(stateID: .hidSystemState)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kvm_helper", binaryMessenger: registrar.messenger)
    let instance = KvmHelperPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let inputEventChannel = FlutterEventChannel(name: "kvm_helper/inputs", binaryMessenger: registrar.messenger)
    inputEventChannel.setStreamHandler(GeneralStreamHandler(
      onListen: { [weak instance] arguments, events in
        instance?.inputSink = events
        // Parse the types parameter from arguments
        if let args = arguments as? [String: Any],
           let typesList = args["types"] as? [String] {
          instance?.allowedInputTypes = Set(typesList.compactMap { InputType(rawValue: $0) })
        } else {
          // Fallback to all types if parsing fails
          instance?.allowedInputTypes = Set(InputType.allCases)
        }
        instance?.startEventTap()
        return nil
      },
      onCancel: { [weak instance] arguments in
        instance?.inputSink = nil
        instance?.stopEventTap()
        return nil
      }
    ))

    let monitorEventChannel = FlutterEventChannel(name: "kvm_helper/monitors", binaryMessenger: registrar.messenger)
    monitorEventChannel.setStreamHandler(GeneralStreamHandler(
      onListen: { [weak instance] arguments, events in
        instance?.monitorSink = events
        instance?.startMonitorDetection()
        return nil
      },
      onCancel: { [weak instance] arguments in
        instance?.monitorSink = nil
        instance?.stopMonitorDetection()
        return nil
      }
    ))
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestPermission(call: call, result: result)
    case "isPermissionGranted":
      isPermissionGranted(call: call, result: result)
    case "injectMouseInput":
      injectMouseInput(call: call, result: result)
    case "injectKeyboardInput":
      injectKeyboardInput(call: call, result: result)
    case "setBlockedInputs":
      setBlockedInputs(call: call, result: result)
    case "getBlockedInputs":
      getBlockedInputs(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if !AXIsProcessTrusted() {
      // Open System Preferences to Accessibility
      let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
      NSWorkspace.shared.open(url)
      result(false)
    } else {
      result(true)
    }
  }

  private func isPermissionGranted(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let typesList = args?["types"] as? [String]
    
    // For macOS, all permissions (capture and injection) are the same - they require Accessibility permission
    let hasPermission = AXIsProcessTrusted()
    
    if typesList == nil {
      // When types is null, return false if any permission is not granted
      result(hasPermission)
    } else {
      // For specific types, return the same permission status
      result(hasPermission)
    }
  }

  private func startEventTap() {
    guard eventTap == nil else { return }
    
    // Only start if we have permission
    guard AXIsProcessTrusted() else { return }
    
    // Break up the complex event mask expression
    let keyDownMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
    let keyUpMask = CGEventMask(1 << CGEventType.keyUp.rawValue)
    let flagsChangedMask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
    let leftMouseDownMask = CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
    let leftMouseUpMask = CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
    let rightMouseDownMask = CGEventMask(1 << CGEventType.rightMouseDown.rawValue)
    let rightMouseUpMask = CGEventMask(1 << CGEventType.rightMouseUp.rawValue)
    let mouseMovedMask = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
    let leftMouseDraggedMask = CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
    let rightMouseDraggedMask = CGEventMask(1 << CGEventType.rightMouseDragged.rawValue)
    let scrollWheelMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
    let otherMouseDownMask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
    let otherMouseUpMask = CGEventMask(1 << CGEventType.otherMouseUp.rawValue)
    let otherMouseDraggedMask = CGEventMask(1 << CGEventType.otherMouseDragged.rawValue)
    
    let eventMask = keyDownMask | keyUpMask | flagsChangedMask | leftMouseDownMask | leftMouseUpMask | rightMouseDownMask | rightMouseUpMask | mouseMovedMask | leftMouseDraggedMask | rightMouseDraggedMask | scrollWheelMask | otherMouseDownMask | otherMouseUpMask | otherMouseDraggedMask
    
    eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                place: .headInsertEventTap,
                                options: .defaultTap,
                                eventsOfInterest: eventMask,
                                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
      let plugin = Unmanaged<KvmHelperPlugin>.fromOpaque(refcon!).takeUnretainedValue()
      
      // Check if this event type should be blocked
      let shouldBlock = plugin.shouldBlockEvent(type: type)
      
      plugin.handleEvent(type: type, event: event)
      
      // Return nil to block the event, or the event to allow it through
      return shouldBlock ? nil : Unmanaged.passUnretained(event)
    }, userInfo: Unmanaged.passUnretained(self).toOpaque())
    
    if let tap = eventTap {
      runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
      if let source = runLoopSource {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
      }
    }
  }

  private func stopEventTap() {
    if let tap = eventTap {
      CGEvent.tapEnable(tap: tap, enable: false)
      eventTap = nil
    }
    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
      runLoopSource = nil
    }
  }

  private func handleEvent(type: CGEventType, event: CGEvent) {
    // Check if this event type should be allowed based on allowedInputTypes
    let shouldAllow = shouldAllowEvent(type: type)
    if !shouldAllow {
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      switch type {
      case .keyDown, .keyUp, .flagsChanged:
        self?.handleKeyboardEvent(type: type, event: event)
      case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
           .mouseMoved, .leftMouseDragged, .rightMouseDragged, .scrollWheel,
           .otherMouseDown, .otherMouseUp, .otherMouseDragged:
        self?.handleMouseEvent(type: type, event: event)
      default:
        break
      }
    }
  }

  private func handleKeyboardEvent(type: CGEventType, event: CGEvent) {
    let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags
    
    var eventType: String
    switch type {
    case .keyDown:
      eventType = "keyDown"
    case .keyUp:
      eventType = "keyUp"
    case .flagsChanged:
      eventType = "flagsChanged"
    default:
      return
    }
    
    var modifiers: [String] = []
    if flags.contains(.maskShift) { modifiers.append("shift") }
    if flags.contains(.maskControl) { modifiers.append("control") }
    if flags.contains(.maskAlternate) { modifiers.append("option") }
    if flags.contains(.maskCommand) { modifiers.append("command") }
    if flags.contains(.maskAlphaShift) { modifiers.append("capsLock") }
    if flags.contains(.maskSecondaryFn) { modifiers.append("function") }
    if flags.contains(.maskNumericPad) { modifiers.append("numericPad") }
    if flags.contains(.maskHelp) { modifiers.append("help") }
    
    let eventData: [String: Any] = [
      "kind": "keyboard",
      "code": keyCode,
      "type": eventType,
      "modifiers": modifiers,
      "character": NSNull(),
      "flag": event.getIntegerValueField(.eventSourceUserData),
    ]
    
    inputSink?(eventData)
  }

  private func handleMouseEvent(type: CGEventType, event: CGEvent) {
    let location = event.location
    
    var eventType: String
    var button: String? = nil
    var deltaX: Double = 0
    var deltaY: Double = 0
    var deltaZ: Double = 0
    
    switch type {
    case .leftMouseDown:
      eventType = "leftMouseDown"
      button = "left"
    case .leftMouseUp:
      eventType = "leftMouseUp"
      button = "left"
    case .rightMouseDown:
      eventType = "rightMouseDown"
      button = "right"
    case .rightMouseUp:
      eventType = "rightMouseUp"
      button = "right"
    case .mouseMoved:
      eventType = "mouseMoved"
    case .leftMouseDragged:
      eventType = "leftMouseDragged"
      button = "left"
    case .rightMouseDragged:
      eventType = "rightMouseDragged"
      button = "right"
    case .scrollWheel:
      eventType = "scrollWheel"
      deltaX = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
      deltaY = event.getDoubleValueField(.scrollWheelEventDeltaAxis2)
      deltaZ = event.getDoubleValueField(.scrollWheelEventDeltaAxis3)
    case .otherMouseDown:
      eventType = "otherMouseDown"
      button = "center"
    case .otherMouseUp:
      eventType = "otherMouseUp"
      button = "center"
    case .otherMouseDragged:
      eventType = "otherMouseDragged"
      button = "center"
    default:
      return
    }
    
    let eventData: [String: Any] = [
      "kind": "mouse",
      "x": location.x,
      "y": location.y,
      "type": eventType,
      "button": button ?? NSNull(),
      "deltaX": deltaX,
      "deltaY": deltaY,
      "deltaZ": deltaZ,
      "flag": event.getIntegerValueField(.eventSourceUserData),
    ]
    
    inputSink?(eventData)
  }

  private func injectMouseInput(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let x = args["x"] as? Double,
          let y = args["y"] as? Double,
          let typeString = args["type"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid mouse event arguments", details: nil))
      return
    }
    
    var eventType: CGEventType
    switch typeString {
    case "leftMouseDown": eventType = .leftMouseDown
    case "leftMouseUp": eventType = .leftMouseUp
    case "rightMouseDown": eventType = .rightMouseDown
    case "rightMouseUp": eventType = .rightMouseUp
    case "mouseMoved": eventType = .mouseMoved
    case "leftMouseDragged": eventType = .leftMouseDragged
    case "rightMouseDragged": eventType = .rightMouseDragged
    case "scrollWheel": eventType = .scrollWheel
    case "otherMouseDown": eventType = .otherMouseDown
    case "otherMouseUp": eventType = .otherMouseUp
    case "otherMouseDragged": eventType = .otherMouseDragged
    default:
      result(FlutterError(code: "INVALID_EVENT_TYPE", message: "Invalid mouse event type", details: nil))
      return
    }
    
    let event = CGEvent(mouseEventSource: customEventSource, mouseType: eventType, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left)
    event?.setIntegerValueField(.eventSourceUserData, value: args["flag"] as! Int64)
    event?.post(tap: .cghidEventTap)
    
    result(nil)
  }

  private func injectKeyboardInput(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let keyCode = args["code"] as? Int,
          let typeString = args["type"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid keyboard event arguments", details: nil))
      return
    }
    
    var eventType: CGEventType
    switch typeString {
    case "keyDown": eventType = .keyDown
    case "keyUp": eventType = .keyUp
    case "flagsChanged": eventType = .flagsChanged
    default:
      result(FlutterError(code: "INVALID_EVENT_TYPE", message: "Invalid keyboard event type", details: nil))
      return
    }
    
    // Handle modifiers
    var flags: CGEventFlags = []
    if let modifiers = args["modifiers"] as? [String] {
      for modifier in modifiers {
        switch modifier {
        case "shift": flags.insert(.maskShift)
        case "control": flags.insert(.maskControl)
        case "option": flags.insert(.maskAlternate)
        case "command": flags.insert(.maskCommand)
        case "capsLock": flags.insert(.maskAlphaShift)
        case "function": flags.insert(.maskSecondaryFn)
        case "numericPad": flags.insert(.maskNumericPad)
        case "help": flags.insert(.maskHelp)
        default: break
        }
      }
    }
    
    let event = CGEvent(keyboardEventSource: customEventSource, virtualKey: CGKeyCode(keyCode), keyDown: eventType == .keyDown)
    event?.flags = flags
    event?.setIntegerValueField(.eventSourceUserData, value: args["flag"] as! Int64)
    event?.post(tap: .cghidEventTap)
    
    result(nil)
  }

  private func setBlockedInputs(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let typesList = args?["types"] as? [String]

    // Convert typesList to [InputType], fallback to allCases
    let inputTypes: [InputType]
    if let typesList = typesList {
      inputTypes = typesList.compactMap { InputType(rawValue: $0) }
    } else {
      inputTypes = []
    }
    blockedInputTypes = Set(inputTypes)

    // Update cursor visibility based on current blockedInputTypes state
    if blockedInputTypes.contains(.mouse) {
      hideCursor()
    } else {
      showCursor()
    }

    result(true)
  }

  private func getBlockedInputs(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let blockedTypesList = blockedInputTypes.map { $0.rawValue }
    result(blockedTypesList)
  }

  private func shouldBlockEvent(type: CGEventType) -> Bool {
    switch type {
    case .keyDown, .keyUp, .flagsChanged:
      return blockedInputTypes.contains(.keyboard)
    case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
         .mouseMoved, .leftMouseDragged, .rightMouseDragged, .scrollWheel,
         .otherMouseDown, .otherMouseUp, .otherMouseDragged:
      return blockedInputTypes.contains(.mouse)
    default:
      return false
    }
  }

  private func shouldAllowEvent(type: CGEventType) -> Bool {
    switch type {
    case .keyDown, .keyUp, .flagsChanged:
      return allowedInputTypes.contains(.keyboard)
    case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
         .mouseMoved, .leftMouseDragged, .rightMouseDragged, .scrollWheel,
         .otherMouseDown, .otherMouseUp, .otherMouseDragged:
      return allowedInputTypes.contains(.mouse)
    default:
      return false
    }
  }

  private func hideCursor() {
    if originalCursor != nil {
      return
    }
    
    DispatchQueue.main.async {
      if self.originalCursor == nil {
        self.originalCursor = NSCursor.current
      }
      NSCursor.hide()
    }
  }

  private func showCursor() {
    if originalCursor == nil {
      return
    }
    
    DispatchQueue.main.async {
      NSCursor.unhide()
      if let originalCursor = self.originalCursor {
        originalCursor.set()
        self.originalCursor = nil
      }
    }
  }

  // MARK: - Monitor Methods

  private func startMonitorDetection() {
    // Send initial monitor list
    sendMonitorList()

    // Remove any existing observer
    if let observer = screenParametersObserver {
        NotificationCenter.default.removeObserver(observer)
        screenParametersObserver = nil
    }

    // Observe screen parameter changes
    screenParametersObserver = NotificationCenter.default.addObserver(
        forName: NSApplication.didChangeScreenParametersNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.sendMonitorList()
    }
  }

  private func stopMonitorDetection() {
    if let observer = screenParametersObserver {
        NotificationCenter.default.removeObserver(observer)
        screenParametersObserver = nil
    }
  }

  private func sendMonitorList() {
    let monitors = getCurrentMonitors()
    monitorSink?(monitors)
  }

  private func getCurrentMonitors() -> [[String: Any]] {
    var monitors: [[String: Any]] = []
    
    // Get all screens
    let screens = NSScreen.screens
    for (index, screen) in screens.enumerated() {
      let deviceDescription = screen.deviceDescription
      let displayID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
      
      // Use CGDisplayBounds for accurate global coordinates
      let bounds = CGDisplayBounds(displayID)
      let monitor: [String: Any] = [
        "id": "\(displayID)",
        "name": "Display \(index + 1)",
        "x": bounds.origin.x,
        "y": bounds.origin.y,
        "width": bounds.size.width,
        "height": bounds.size.height,
      ]
      
      monitors.append(monitor)
    }
    
    return monitors
  }

  deinit {
    stopEventTap()
    stopMonitorDetection()
    showCursor()
  }
}

private class GeneralStreamHandler: NSObject, FlutterStreamHandler {
  private let onListen: (Any?, @escaping FlutterEventSink) -> FlutterError?
  private let onCancel: (Any?) -> FlutterError?
  
  init(onListen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?, 
       onCancel: @escaping (Any?) -> FlutterError?) {
    self.onListen = onListen
    self.onCancel = onCancel
  }
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    return onListen(arguments, events)
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return onCancel(arguments)
  }
}
