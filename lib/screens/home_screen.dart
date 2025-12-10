// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent_plus.dart'; // Corrected import

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
  // Hold the previously selected index to detect when we need to re-initialize the camera
  int _lastSelectedCameraIndex = 0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    
    // Initialize with the default camera (index 0) from the controller
    _lastSelectedCameraIndex = context.read<AppController>().selectedCameraIndex;
    _initializeCamera(_lastSelectedCameraIndex);
    _startDemoSimulation(); // DEMO ONLY
  }
  
  // --- Camera Initialization and Switching Logic ---
  Future<void> _initializeCamera(int cameraIndex) async {
    if (widget.cameras.isEmpty || cameraIndex >= widget.cameras.length) return;

    // 1. Dispose of the old controller first
    await _cameraController?.dispose(); 

    // 2. Select the camera based on the index (0 for front, 1 for back)
    final CameraDescription selectedCamera = widget.cameras[cameraIndex];

    _cameraController = CameraController(
      selectedCamera, 
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      // 3. Initialize new controller
      await _cameraController!.initialize();
      _lastSelectedCameraIndex = cameraIndex; // Update the check variable
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera error during initialization: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 4. Listen for changes in the AppController's selectedCameraIndex
    final controller = context.watch<AppController>();
    if (controller.selectedCameraIndex != _lastSelectedCameraIndex) {
      // Re-initialize camera only if the index has actually changed
      _initializeCamera(controller.selectedCameraIndex);
    }
  }
  
  // --- Lifecycle and Permissions (Mostly unchanged, ensure correct imports) ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appController = context.read<AppController>();
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      // Important: Also hide the preview and reverse the animation when pausing
      if (appController.isCameraPreviewVisible) {
        appController.toggleCameraPreview();
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(appController.selectedCameraIndex);
    }
  }
  
  Future<void> _checkPermissions() async {
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }
    // ... (rest of permission check remains the same) ...
    bool accessibilityEnabled = false; 
    
    if (!accessibilityEnabled && mounted) {
      _showPermissionPopup(context);
    }
  }

  // ... (_showPermissionPopup and _openAccessibilitySettings remain the same) ...
  // ... (_startDemoSimulation remains the same) ...
  // ... (dispose remains the same) ...


  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    const double cameraPreviewHeight = 180.0; // Fixed height for the camera box

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background
          if (!controller.isCameraPreviewVisible)
             Container(color: Theme.of(context).colorScheme.surface),
          
          // 2. Camera Preview Box (The box that shows above the controls)
          if (controller.isCameraPreviewVisible && _cameraController != null && _cameraController!.value.isInitialized)
            // Use Positioned and AnimatedContainer to manage the size/animation appearance
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: cameraPreviewHeight,
                width: MediaQuery.of(context).size.width,
                // Add padding and background for the "box" look
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), 
                      blurRadius: 10, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    // Fit the camera stream into the box
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),

          // 3. Main UI Layout (Animated to move down when camera is shown)
          // Use AnimatedPositioned, controlled by the offset in AppController
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: controller.cameraControlsVerticalOffset, // Drives the animation
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (AppBar Row with Settings and Status remains the same) ...
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

                    // Control Toggle Button (remains the same)
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

                    // Show Cursor/Camera Feed Controls (now uses subtitle for camera info)
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
          ),

          // 4. Fake Cursor Overlay (Demo) - remains the same
          if (controller.isControlActive && controller.isCursorVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: controller.cursorPosition.dx - 15, // Center the cursor
              top: controller.cursorPosition.dy - 15, // Center the cursor
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