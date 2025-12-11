// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import 'package:Handy/services/gesture_channel_service.dart'; // Import the new service

class AppController extends ChangeNotifier {
  // --- Services ---
  final GestureChannelService _gestureService = GestureChannelService(); // Initialize the new service

  // asved preferences
  static const _cursorVisibilityKey = 'isCursorVisible';
  bool _isCursorVisible = false;

  // --- App State ---
  bool _isControlActive = false;
  bool _isCursorVisible = false;
  bool _isCameraPreviewVisible = false;
  int _selectedCameraIndex = 0; 
  
  // Hand/Gesture State (used for UI feedback)
  bool _isHandDetected = false;
  String _currentGestureText = "OFF";
  Offset _cursorPosition = const Offset(0, 0);

  // --- Getters ---
  bool get isControlActive => _isControlActive;
  bool get isCursorVisible => _isCursorVisible;
  bool get isCameraPreviewVisible => _isCameraPreviewVisible;
  int get selectedCameraIndex => _selectedCameraIndex; 
  
  bool get isHandDetected => _isHandDetected;
  String get currentGestureText => _currentGestureText;
  Offset get cursorPosition => _cursorPosition;

  // --- Actions ---

  AppController() {
    loadSettings();
  }

  // --- Persistence Methods ---
  
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load Cursor Visibility State
    _isCursorVisible = prefs.getBool(_cursorVisibilityKey) ?? false;
    
    // 2. If cursor was saved as visible, immediately turn on the native overlay service.
    if (_isCursorVisible) {
      // NOTE: We rely on the native service to handle the display
      // We don't have a cursor position yet, but we enable the service.
      _gestureService.toggleCursorVisibility(true); 
    }

    notifyListeners();
  }

  Future<void> _saveCursorVisibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cursorVisibilityKey, value);
  }

  void toggleControl() {
    _isControlActive = !_isControlActive;
    if (!_isControlActive) {
      if (_isCursorVisible) {
        // Only call native to hide if it was visible
        _gestureService.toggleCursorVisibility(false);
      }
      _currentGestureText = "OFF";
      _isHandDetected = false;
    } else {
      if (_isCursorVisible) {
            _gestureService.toggleCursorVisibility(true);
        }
    }
    notifyListeners();
  }

  void toggleCursorVisibility(bool value) {
    _isCursorVisible = value;
    
    // 1. Save the new state persistently
    _saveCursorVisibility(value); 
    
    // 2. Control the native system overlay
    // Only toggle the native service if the overall control (power button) is active
    if (_isControlActive) {
      _gestureService.toggleCursorVisibility(value);
    }
    
    notifyListeners();
  }

  void toggleCameraPreview() {
    _isCameraPreviewVisible = !_isCameraPreviewVisible;
    notifyListeners();
  }

  void setSelectedCameraIndex(int index) {
    _selectedCameraIndex = index;
    notifyListeners();
  }
  
  

  // --- Core Gesture Logic ---
  // NOTE: Ensure your existing 'executeGesture' is complete as shown here:
  Future<void> executeGesture(String gestureType, Offset screenPosition) async {
    if (!_isControlActive) return;

    _cursorPosition = screenPosition; // Update cursor position

    // Convert to physical pixels (or use as is for simulation)
    final x = screenPosition.dx.round();
    final y = screenPosition.dy.round();

    bool success = false;
  
    switch (gestureType) {
      case "Pinch (Click)": // Click/Tap
      case "Holding": // Often treated as a long press or click in simplified demos
        success = await _gestureService.performClick(x, y);
        break;
      case "Swipe Left":
        success = await _gestureService.performSwipe(
          startX: x, 
          startY: y, 
          endX: x - 200, // Move 200 pixels left
          endY: y,
          duration: 200,
        );
        break;
      case "Swipe Right":
        success = await _gestureService.performSwipe(
          startX: x, 
          startY: y, 
          endX: x + 200, // Move 200 pixels right
          endY: y,
          duration: 200,
        );
        break;
      case "Swipe Down":
        success = await _gestureService.performSwipe(
          startX: x, 
          startY: y, 
          endX: x, 
          endY: y + 200, // Move 200 pixels down
          duration: 200,
        );
        break;
      default:
        break;
    }
  } 

  // --- DEMO ONLY: Simulates incoming CV data and gesture execution ---
  void simulateGesture(String gesture, bool isDetected) {
    _isHandDetected = isDetected;
  _currentGestureText = gesture;

    if (isDetected && _isControlActive) {
      // Generate a new mock position or use the current one
      if (_cursorPosition == const Offset(0, 0)) {
        // Use the center of the screen as a default start position for the demo
        _cursorPosition = Offset(
          WidgetsBinding.instance.window.physicalSize.width / (2 * WidgetsBinding.instance.window.devicePixelRatio),
          WidgetsBinding.instance.window.physicalSize.height / (2 * WidgetsBinding.instance.window.devicePixelRatio),
        ); 
      }

      // Call the real execution function for the detected gesture
      executeGesture(gesture, _cursorPosition);
    } else {
      // When no hand is detected, we don't execute a gesture.
      // The previous state update (e.g., cursor position) is enough.
    }
  
    notifyListeners();
  }
}
