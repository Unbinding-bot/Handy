// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/gesture_channel_service.dart';

class AppController extends ChangeNotifier {

  final GestureChannelService _channelService = GestureChannelService();
  StreamSubscription? _gestureSubscription;
  
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


  // --- Initialization and setup ---
  AppController(){

    _listenToNativeEvents();
  }

  @override
  void dispose(){
    _gestureSubscription?.cancel();
    super.dispose();
  }

  // --- Stream Listener ---
  void _listenToNativeEvents(){
    // Subscribe
    _gestureSubscription = _channelService.gestureEvents.listen((data) {
      _currentGestureText = data['gesture'] ?? 'No Gesture';
      _isHandDetected = data['isHandDetected'] ?? false;

      if (_isHandDetected && data['cursorX'] != null && data['cursorY'] != null) {
        // recieve coordinates
        _cursorPosition = Offset(data['cursorX'], data['cursorY']);
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint("Gesture Stream Error: $error");
      simulateGesture("Stream Error!", true); // Indicate error to user
    })
  }



  // --- Actions ---

  void toggleControl() {
    _isControlActive = !_isControlActive;
    if (_isControlActive) {
      _channelService.startTracking(); // START NATIVE SERVICE
    } else {
      _channelService.stopTracking();  // STOP NATIVE SERVICE
      // Reset status when turning off
      simulateGesture("Control Off", false);
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

  void handleGesture(String gesture) {
    if (_isControlActive) {
      _channelService.performSystemAction(gesture);
    }
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