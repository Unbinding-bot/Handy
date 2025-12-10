import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // For Offset and Rect

class GestureChannelService {
  // Method Channel: Used for calling one-off commands (e.g., enable/disable service)
  static const MethodChannel _methodChannel = MethodChannel('com.handy.gesture_control/actions');
  
  // Event Channel: Used for streaming continuous data from native (e.g., gesture events, cursor coordinates)
  static const EventChannel _eventChannel = EventChannel('com.handy.gesture_control/events');

  // Stream to expose gesture/status updates to the Flutter UI
  Stream<Map<String, dynamic>> get gestureEvents => _eventChannel.receiveBroadcastStream().cast<Map<String, dynamic>>();

  // --- Methods to Call Native Code ---

  /// Sends a command to start the native tracking and accessibility service.
  Future<void> startTracking() async {
    try {
      await _methodChannel.invokeMethod('startTracking');
      debugPrint('Native: startTracking command sent successfully.');
    } catch (e) {
      debugPrint('Native Error: Failed to start tracking: $e');
    }
  }

  /// Sends a command to stop the native tracking and accessibility service.
  Future<void> stopTracking() async {
    try {
      await _methodChannel.invokeMethod('stopTracking');
      debugPrint('Native: stopTracking command sent successfully.');
    } catch (e) {
      debugPrint('Native Error: Failed to stop tracking: $e');
    }
  }

  /// Sends a specific system action command (e.g., HOME, BACK, CLICK).
  Future<void> performSystemAction(String action) async {
    try {
      // action can be 'CLICK', 'SWIPE_LEFT', 'HOME', etc.
      await _methodChannel.invokeMethod('performSystemAction', {'action': action});
      debugPrint('Native: System action "$action" performed.');
    } catch (e) {
      debugPrint('Native Error: Failed to perform system action: $e');
    }
  }

  // --- Example of receiving data from the stream ---
  // The stream will emit a Map, which we'll handle in the AppController.
  /*
  The expected map format from native code:
  {
    "gesture": "Pinch (Click)",
    "cursorX": 540.0,
    "cursorY": 1200.0,
    "isHandDetected": true
  }
  */
}