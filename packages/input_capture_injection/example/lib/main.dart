import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:input_capture_injection/input_capture_injection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _inputCaptureInjectionPlugin = InputCaptureInjection();

  bool _permissionGranted = false;
  bool _isCapturing = false;

  final List<String> _inputEvents = [];
  final ScrollController _inputEventsScrollController = ScrollController();
  StreamSubscription<Input>? _inputSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _inputSubscription?.cancel();
    _inputEventsScrollController.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        platformVersion = 'macOS ${macOsInfo.osRelease}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        platformVersion = 'Windows ${windowsInfo.buildNumber}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        platformVersion = 'Linux ${linuxInfo.name} ${linuxInfo.version}';
      } else {
        platformVersion = 'Unknown platform';
      }
    } catch (e) {
      platformVersion = 'Failed to get platform version: $e';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // Check initial permissions
    await checkPermissions();
  }

  Future<void> checkPermissions() async {
    final permissionStatus = await _inputCaptureInjectionPlugin
        .isPermissionGranted();

    if (mounted) {
      setState(() {
        _permissionGranted = permissionStatus;
      });
    }
  }

  Future<void> requestPermission() async {
    try {
      final granted = await _inputCaptureInjectionPlugin.requestPermission();
      if (mounted) {
        setState(() {
          _permissionGranted = granted;
        });
      }
      await checkPermissions();
    } catch (e) {
      _addInputEvent('Error requesting permission: $e');
    }
  }

  Future<void> startCapture() async {
    if (!_permissionGranted) {
      _addInputEvent('Permission not granted');
      return;
    }
    try {
      _inputSubscription = _inputCaptureInjectionPlugin.inputs().listen((
        event,
      ) {
        if (event is KeyboardInput) {
          _addInputEvent(
            'Keyboard: ${event.type} - Key: ${event.code} - Modifiers: ${event.modifiers}',
          );
        } else if (event is MouseInput) {
          _addInputEvent(
            'Mouse: ${event.type} - Pos: (${event.x.toStringAsFixed(1)}, ${event.y.toStringAsFixed(1)}) - Button: ${event.button}',
          );
        } else {
          _addInputEvent('Unknown input event: $event');
        }
      });
      if (mounted) {
        setState(() {
          _isCapturing = true;
        });
      }
      _addInputEvent('Started capturing input events');
    } catch (e) {
      _addInputEvent('Error starting input capture: $e');
    }
  }

  Future<void> stopCapture() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    if (mounted) {
      setState(() {
        _isCapturing = false;
      });
    }
    _addInputEvent('Stopped capturing input events');
  }

  Future<void> injectTestKeyEvent() async {
    if (!_permissionGranted) {
      _addInputEvent('Permission not granted');
      return;
    }

    try {
      await _inputCaptureInjectionPlugin.injectInput(
        KeyboardInput(
          code: 0x00, // Key code for 'A'
          type: KeyboardInputType.keyDown,
          modifiers: [KeyModifier.shift],
          character: 'A',
          // timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _addInputEvent('Injected keyboard event: Shift+A');
    } catch (e) {
      _addInputEvent('Error injecting keyboard event: $e');
    }
  }

  Future<void> injectTestMouseEvent() async {
    if (!_permissionGranted) {
      _addInputEvent('Permission not granted');
      return;
    }

    try {
      await _inputCaptureInjectionPlugin.injectInput(
        MouseInput(
          x: 100.0,
          y: 100.0,
          type: MouseInputType.leftMouseDown,
          button: MouseButton.left,
          deltaX: 0.0,
          deltaY: 0.0,
          deltaZ: 0.0,
          // timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _addInputEvent('Injected mouse event: Left click at (100, 100)');
    } catch (e) {
      _addInputEvent('Error injecting mouse event: $e');
    }
  }

  Future<void> blockInputsFor3Seconds() async {
    if (!_permissionGranted) {
      _addInputEvent('Permission not granted');
      return;
    }

    try {
      _addInputEvent('Blocking all inputs for 3 seconds...');

      // Block all inputs
      await _inputCaptureInjectionPlugin.setInputBlocked(true);

      // Show current blocked inputs
      final blockedInputs = await _inputCaptureInjectionPlugin
          .getBlockedInputs();
      _addInputEvent(
        'Currently blocked: ${blockedInputs.map((t) => t.name).join(', ')}',
      );

      // Wait for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      // Unblock all inputs
      await _inputCaptureInjectionPlugin.setInputBlocked(false);

      _addInputEvent('Input blocking completed');
    } catch (e) {
      _addInputEvent('Error blocking inputs: $e');
    }
  }

  Future<void> blockMouseFor3Seconds() async {
    if (!_permissionGranted) {
      _addInputEvent('Permission not granted');
      return;
    }

    try {
      _addInputEvent('Blocking mouse input for 3 seconds...');

      // Block mouse input
      await _inputCaptureInjectionPlugin.setInputBlocked(true, {
        InputType.mouse,
      });

      // Show current blocked inputs
      final blockedInputs = await _inputCaptureInjectionPlugin
          .getBlockedInputs();
      _addInputEvent(
        'Currently blocked: ${blockedInputs.map((t) => t.name).join(', ')}',
      );

      // Wait for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      // Unblock mouse input
      await _inputCaptureInjectionPlugin.setInputBlocked(false, {
        InputType.mouse,
      });

      _addInputEvent('Mouse blocking completed');
    } catch (e) {
      _addInputEvent('Error blocking mouse: $e');
    }
  }

  Future<void> blockKeyboardFor3Seconds() async {
    if (!_permissionGranted) {
      _addInputEvent('Permission not granted');
      return;
    }

    try {
      _addInputEvent('Blocking keyboard input for 3 seconds...');

      // Block keyboard input
      await _inputCaptureInjectionPlugin.setInputBlocked(true, {
        InputType.keyboard,
      });

      // Show current blocked inputs
      final blockedInputs = await _inputCaptureInjectionPlugin
          .getBlockedInputs();
      _addInputEvent(
        'Currently blocked: ${blockedInputs.map((t) => t.name).join(', ')}',
      );

      // Wait for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      // Unblock keyboard input
      await _inputCaptureInjectionPlugin.setInputBlocked(false, {
        InputType.keyboard,
      });

      _addInputEvent('Keyboard blocking completed');
    } catch (e) {
      _addInputEvent('Error blocking keyboard: $e');
    }
  }

  void _addInputEvent(String event) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final eventText = '[$timestamp] $event';
    if (mounted) {
      setState(() {
        _inputEvents.add(eventText);
        if (_inputEvents.length > 200) {
          _inputEvents.removeAt(0);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_inputEventsScrollController.hasClients) {
          _inputEventsScrollController.animateTo(
            _inputEventsScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _clearInputEvents() {
    setState(() {
      _inputEvents.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Input Capture & Injection Test'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform: $_platformVersion',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Permission: ${_permissionGranted ? "✅ Granted" : "❌ Not Granted"}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Permission button
              ElevatedButton(
                onPressed: requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _permissionGranted
                      ? Colors.green
                      : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _permissionGranted
                      ? 'Permission: Granted'
                      : 'Request Permission',
                ),
              ),

              const SizedBox(height: 16),

              // Capture control
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCapturing ? null : startCapture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCapturing
                            ? Colors.grey
                            : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isCapturing ? 'Capturing...' : 'Start Capture',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCapturing ? stopCapture : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCapturing
                            ? Colors.red
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Stop Capture'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Injection test buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _permissionGranted ? injectTestKeyEvent : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _permissionGranted
                            ? Colors.purple
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Inject Key Event'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _permissionGranted
                          ? injectTestMouseEvent
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _permissionGranted
                            ? Colors.purple
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Inject Mouse Event'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Input blocking test buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _permissionGranted
                          ? blockKeyboardFor3Seconds
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _permissionGranted
                            ? Colors.orange
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Block Keyboard\n3 Seconds'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _permissionGranted
                          ? blockMouseFor3Seconds
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _permissionGranted
                            ? Colors.purple
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Block Mouse\n3 Seconds'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _permissionGranted ? blockInputsFor3Seconds : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _permissionGranted
                        ? Colors.red
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Block All Inputs for 3 Seconds'),
                ),
              ),

              const SizedBox(height: 16),

              // Events display
              Row(
                children: [
                  const Text(
                    'Input Events:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearInputEvents,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    controller: _inputEventsScrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _inputEvents.length,
                    itemBuilder: (context, index) {
                      final event = _inputEvents[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          event,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
