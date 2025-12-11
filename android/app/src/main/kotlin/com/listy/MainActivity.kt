package com.handy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // 1. Define the unique channel name used by Dart
    private val CHANNEL = "com.handy/gestures"

    // Reference to the Accessibility Service (static so it can be accessed without creating a new Activity)
    companion object {
        var accessibilityService: GestureAccessibilityService? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            
            // Check if the service is active and available
            val service = accessibilityService
            if (service == null) {
                result.error("UNAVAILABLE", "Accessibility Service is not running or active.", null)
                return@setMethodCallHandler
            }

            // 2. Handle incoming method calls from Dart
            when (call.method) {
                "performSwipe" -> {
                    val startX = call.argument<Int>("startX") ?: 0
                    val startY = call.argument<Int>("startY") ?: 0
                    val endX = call.argument<Int>("endX") ?: 0
                    val endY = call.argument<Int>("endY") ?: 0
                    val duration = call.argument<Long>("duration") ?: 300L

                    service.performSwipe(startX, startY, endX, endY, duration)
                    result.success(true)
                }
                "performClick" -> {
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    
                    service.performClick(x, y)
                    result.success(true)
                }
                // Placeholder for other commands (e.g., isServiceEnabled)
                "isServiceEnabled" -> {
                    // Check if the service instance is currently bound/active
                    result.success(accessibilityService != null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}