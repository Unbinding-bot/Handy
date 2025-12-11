// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

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
  int _lastSelectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndSetup(); // Updated permission check method

    _lastSelectedCameraIndex = context.read<AppController>().selectedCameraIndex;
    _initializeCamera(_lastSelectedCameraIndex);
    _startDemoSimulation(); // DEMO ONLY
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    if (widget.cameras.isEmpty || cameraIndex >= widget.cameras.length) return;

    await _cameraController?.dispose();

    final CameraDescription selectedCamera = widget.cameras[cameraIndex];

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      _lastSelectedCameraIndex = cameraIndex;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera error during initialization: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<AppController>();
    if (controller.selectedCameraIndex != _lastSelectedCameraIndex) {
      _initializeCamera(controller.selectedCameraIndex);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appController = context.read<AppController>();
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      // Also hide the native overlay cursor when the app is backgrounded/paused
      appController.toggleCursorVisibility(false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(appController.selectedCameraIndex);
      // Re-enable the cursor if it was active when the app paused
      if (appController.isCursorVisible) {
          appController.toggleCursorVisibility(true);
      }
    }
  }

  // --- Permission and Utility Methods ---

  Future<void> _checkPermissionsAndSetup() async {
    // 1. Camera Permission
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }

    // 2. Overlay Permission (SYSTEM_ALERT_WINDOW)
    // NOTE: This is required for the system-wide cursor to work!
    bool overlayEnabled = await Permission.systemAlertWindow.isGranted;

    // 3. Accessibility Service Check (MOCK)
    // NOTE: In a real app, this should check the native state via MethodChannel
    bool accessibilityEnabled = false;

    if (!accessibilityEnabled || !overlayEnabled) {
      if (mounted) {
        _showPermissionPopup(context);
      }
    }
  }

  void _showPermissionPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Required Permissions"),
        content: const Text(
          "To control your device, this app requires Accessibility and Overlay (Draw over other apps) permissions.\n\n"
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
              _openRequiredSettings();
            },
            child: const Text("Do Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _openRequiredSettings() async {
    // Open Accessibility Settings
    final accessibilityIntent = AndroidIntent(action: 'android.settings.ACCESSIBILITY_SETTINGS');
    await accessibilityIntent.launch();

    // Check for Overlay permission and request if needed (API 23+)
    if (await Permission.systemAlertWindow.isDenied) {
        // This launches the "Display over other apps" screen for your app
        await openAppSettings();
    }
  }

  // !!! DEMO ONLY: Simulates gestures for the UI !!!
  void _startDemoSimulation() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      final controller = context.read<AppController>();
      if (!controller.isControlActive) return;

      List<String> gestures = ["Swipe Left", "Swipe Right", "Pinch (Click)", "Holding", "Swipe Down"];
      String randomGesture = (gestures..shuffle()).first;

      // Simulate hand detected for a short period
      controller.simulateGesture(randomGesture, true);

      Future.delayed(const Duration(milliseconds: 500), () {
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

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background
          if (!controller.isCameraPreviewVisible)
             Container(color: Theme.of(context).colorScheme.surface),

          // 2. Camera Layer (Full Screen Background with BoxFit.contain)
          if (controller.isCameraPreviewVisible && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                // Use BoxFit.contain to ensure the camera feed fits without being cut.
                fit: BoxFit.contain,
                child: SizedBox(
                  // FIX: Use previewSize and swap height/width for correct aspect ratio.
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // 3. Main UI Layout (Fixed position over the camera feed)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3.1. TOP BAR (Settings and Status)
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

                  const Spacer(), // Pushes Power Button to the center/middle area

                  // 3.2. CONTROL TOGGLE BUTTON
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

                  const Spacer(), // Pushes Control Box to the bottom

                  // 3.3. SHOW CURSOR/CAMERA FEED CONTROLS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.9),
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
                          subtitle: Text(
                            controller.isCameraPreviewVisible
                              ? "Showing ${controller.selectedCameraIndex == 0 ? 'Front' : 'Back'} Camera"
                              : "View what the app sees"
                          ),
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

          // 4. Flutter Cursor Overlay (RE-ADDED)
          // This cursor is only visible INSIDE the app window, used for quick feedback.
          if (controller.isControlActive && controller.isCursorVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              // We use dx/dy directly as they represent logical Flutter pixels
              left: controller.cursorPosition.dx - 15,
              top: controller.cursorPosition.dy - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
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