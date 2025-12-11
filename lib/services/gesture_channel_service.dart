// lib/services/gesture_channel_service.dart
import 'package:flutter/services.dart';

/// Service responsible for communicating with the native Android Accessibility
/// Service to perform system-level gestures (clicks and swipes).
class GestureChannelService {
  // Must match the channel name defined in MainActivity.kt
  static const MethodChannel _channel = MethodChannel('com.handy/gestures');

  /// Performs a click/tap action at the specified screen coordinates.
  /// 
  /// [x] and [y] are screen coordinates in physical pixels.
  Future<bool> performClick(int x, int y) async {
    try {
      final result = await _channel.invokeMethod<bool>('performClick', {
        'x': x,
        'y': y,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      // Log error if the service is unavailable (e.g., permission not granted)
      print("Failed to perform click: '${e.message}'. Service Active? ${await isServiceEnabled()}");
      return false;
    }
  }

  /// Performs a swipe action between two screen coordinates.
  ///
  /// [duration] is the time in milliseconds the swipe should take.
  Future<bool> performSwipe({
    required int startX,
    required int startY,
    required int endX,
    required int endY,
    int duration = 300,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('performSwipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to perform swipe: '${e.message}'. Service Active? ${await isServiceEnabled()}");
      return false;
    }
  }

  Future<bool> toggleCursorVisibility(bool show) async {
    try {
      final result = await _channel.invokeMethod<bool>('toggleCursorVisibility', {
        'show': show,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to toggle cursor visibility: ${e.message}");
      return false;
    }
  }

  Future<bool> updateCursorPosition(int x, int y) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateCursorPosition', {
        'x': x,
        'y': y,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      // This happens frequently during normal operation if the service is stopped, 
      // so it might not need logging unless it fails when expected to be running.
      // print("Failed to update cursor position: ${e.message}"); 
      return false;
    }
  }
  
  /// Checks if the native Accessibility Service is running and active.
  Future<bool> isServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to check service status: ${e.message}");
      return false;
    }
  }
}