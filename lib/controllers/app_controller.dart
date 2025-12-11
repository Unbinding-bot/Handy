// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import 'package:Handy/services/gesture_channel_service.dart'; // Import the new service

class AppController extends ChangeNotifier {
  // --- Services ---
  final GestureChannelService _gestureService = GestureChannelService(); // Initialize the new service

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

  void toggleControl() {
    _isControlActive = !_isControlActive;
    if (!_isControlActive) {
      _currentGestureText = "OFF";
      _isHandDetected = false;
    }
    notifyListeners();
  }

  void toggleCursorVisibility(bool value) {
    _isCursorVisible = value;
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
  
  // --- Core Gesture Logic (New) ---

  /// Executes a system gesture based on computer vision result.
  Future<void> executeGesture(String gestureType, Offset screenPosition) async {
    if (!_isControlActive) return;

    // Simulate the cursor movement for visual feedback
    _cursorPosition = screenPosition;

    // Convert Flutter logical pixels to Android physical pixels
    // NOTE: In a real app, the vision model should output coordinates relative
    // to the camera frame, which would then be mapped to the screen. 
    // Here we use the Offset's DX/DY directly as a mock screen position.
    final x = screenPosition.dx.round();
    final y = screenPosition.dy.round();

    bool success = false;
    
    switch (gestureType) {
      case "Click":
        success = await _gestureService.performClick(x, y);
        break;
      case "Swipe Left":
        // Example: Swipe from the current cursor position to 100 pixels left
        success = await _gestureService.performSwipe(
          startX: x, 
          startY: y, 
          endX: x - 150, 
          endY: y,
          duration: 200,
        );
        break;
      // Add other gestures here (Swipe Right, Up, Down, Long Press, etc.)
      default:
        // No system action required for this recognized gesture
        break;
    }

    // Update UI based on execution status
    if (success) {
      print("Successfully executed: $gestureType at ($x, $y)");
    } else {
      // You can add logic here to show a toast or error if the gesture failed 
      // (e.g., Accessibility service is not enabled).
    }
    
    // For DEMO purposes, we will rely on simulateGesture for UI feedback below.
  }
  
  // --- DEMO ONLY: Simulates incoming CV data and gesture execution ---
  void simulateGesture(String gesture, bool isDetected) {
    _isHandDetected = isDetected;
    _currentGestureText = gesture;
    
    if (isDetected && _isControlActive) {
      // In a real app, this would be the actual CV output position
      // For demo, we just use a random position if not set
      if (_cursorPosition == const Offset(0, 0)) {
        _cursorPosition = const Offset(400, 600); 
      }
      
      // Execute the gesture from the demo
      if (gesture == "Pinch (Click)") {
        executeGesture("Click", _cursorPosition);
      } else if (gesture == "Swipe Left") {
        executeGesture("Swipe Left", _cursorPosition);
      }
      // Note: We don't execute all demo gestures for simplicity, 
      // but the structure is ready.
    }
    
    notifyListeners();
  }
}