// lib/controllers/app_controller.dartimport 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  // --- App Logic State ---
  bool _isControlActive = false;
  bool _isCursorVisible = true;
  bool _isCameraPreviewVisible = false;

  // --- Status State (Gesture Data) ---
  String _currentGestureText = "No hands detected";
  bool _isHandDetected = false;
  Offset _cursorPosition = const Offset(100, 100);

  // --- Getters ---
  bool get isControlActive => _isControlActive;
  bool get isCursorVisible => _isCursorVisible;
  bool get isCameraPreviewVisible => _isCameraPreviewVisible;
  String get currentGestureText => _currentGestureText;
  bool get isHandDetected => _isHandDetected;
  Offset get cursorPosition => _cursorPosition;

  // --- Actions ---

  void toggleControl() {
    _isControlActive = !_isControlActive;
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

  // --- Simulation Logic ---
  void simulateGesture(String gesture, bool handDetected) {
    _currentGestureText = gesture;
    _isHandDetected = handDetected;
    notifyListeners();
  }

  void updateCursorPosition(Offset newPos) {
    _cursorPosition = newPos;
    notifyListeners();
  }
}