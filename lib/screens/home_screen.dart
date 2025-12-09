// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent_plus.dart';

import '../controllers/app_controller.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _initializeCamera();
    _startDemoSimulation(); // DEMO ONLY
  }

  Future<void> _checkPermissions() async {
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }
    
    // Mock check for accessibility (replace with real check in native code)
    bool accessibilityEnabled = false; 
    
    if (!accessibilityEnabled && mounted) {
      _showPermissionPopup(context);
    }
  }

  void _showPermissionPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Required Permissions"),
        content: const Text(
          "To control your device, this app requires Accessibility and Overlay permissions.\n\n"
          "Please enable them in Settings."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Do Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openAccessibilitySettings();
            },
            child: const Text("Do Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccessibilitySettings() async {
    final intent = AndroidIntent(action: 'android.settings.ACCESSIBILITY_SETTINGS');
    await intent.launch();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    _cameraController = CameraController(
      widget.cameras[0], 
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appController = context.read<AppController>();
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      appController.toggleCameraPreview(); // Force off in background
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // !!! DEMO ONLY: Simulates gestures for the UI !!!
  void _startDemoSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final controller = context.read<AppController>();
      if (!controller.isControlActive) return;

      List<String> gestures = ["Swipe Left", "Swipe Right", "Pinch (Click)", "Holding", "Swipe Down"];
      String randomGesture = (gestures..shuffle()).first;
      
      controller.simulateGesture(randomGesture, true);
      
      Future.delayed(const Duration(seconds: 1), () {
        if(mounted) controller.simulateGesture("No hands detected", false);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Camera Layer
          if (controller.isCameraPreviewVisible && _cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: CameraPreview(_cameraController!),
              ),
            ),
          
          if (!controller.isCameraPreviewVisible)
             Container(color: Theme.of(context).colorScheme.surface),

          // 2. Main UI Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: controller.isHandDetected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: controller.isHandDetected ? Colors.green : Colors.red.withOpacity(0.5)
                          )
                        ),
                        child: Row(
                          children: [
                            Icon(
                              controller.isHandDetected ? Icons.front_hand : Icons.do_not_touch,
                              size: 18,
                              color: controller.isHandDetected ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.currentGestureText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: controller.isHandDetected ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  const Spacer(),

                  Center(
                    child: GestureDetector(
                      onTap: controller.toggleControl,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.isControlActive 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          boxShadow: [
                            BoxShadow(
                              color: controller.isControlActive 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.4) 
                                  : Colors.transparent,
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.power_settings_new,
                              size: 60,
                              color: controller.isControlActive 
                                  ? Theme.of(context).colorScheme.onPrimary 
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              controller.isControlActive ? "ACTIVE" : "OFF",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: controller.isControlActive 
                                  ? Theme.of(context).colorScheme.onPrimary 
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                         SwitchListTile(
                          title: const Text("Show Cursor"),
                          value: controller.isCursorVisible,
                          onChanged: controller.toggleCursorVisibility,
                          secondary: const Icon(Icons.mouse),
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text("Show Camera Feed"),
                          subtitle: const Text("View what the app sees"),
                          value: controller.isCameraPreviewVisible,
                          onChanged: (_) => controller.toggleCameraPreview(),
                          secondary: const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fake Cursor Overlay (Demo)
          if (controller.isControlActive && controller.isCursorVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: controller.cursorPosition.dx,
              top: controller.cursorPosition.dy,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.8),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]
                ),
              ),
            ),
        ],
      ),
    );
  }
}