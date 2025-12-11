package com.handy

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.accessibilityservice.GestureDescription.Builder
import android.accessibilityservice.GestureDescription.StrokeDescription
import android.graphics.Path
import android.graphics.Point
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class GestureAccessibilityService : AccessibilityService() {

    // 1. Lifecycle: When the service is successfully connected
    override fun onServiceConnected() {
        super.onServiceConnected()
        // Register this service instance with the MainActivity
        MainActivity.accessibilityService = this
        Toast.makeText(this, "Handy Service Connected", Toast.LENGTH_SHORT).show()
    }

    // 2. Lifecycle: When the service is disconnected or destroyed
    override fun onUnbind(intent: android.content.Intent?): Boolean {
        MainActivity.accessibilityService = null
        Toast.makeText(this, "Handy Service Disconnected", Toast.LENGTH_SHORT).show()
        return super.onUnbind(intent)
    }

    // 3. System Events: Required method, but we don't handle events, only commands
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We do not need to process accessibility events for gesture execution.
    }

    // 4. Interrupt: Required method
    override fun onInterrupt() {
        // Called when the system wants to interrupt the service's feedback.
    }

    // --- Gesture Execution Methods (Called from Flutter via MainActivity) ---

    // Function to perform a simple tap/click
    fun performClick(x: Int, y: Int) {
        val path = Path()
        path.moveTo(x.toFloat(), y.toFloat())

        // Stroke for a tap (duration 1ms is minimal)
        val stroke = StrokeDescription(path, 0, 1) 
        val gesture = Builder().addStroke(stroke).build()
        
        // Dispatch the gesture
        dispatchGesture(gesture, null, null)
    }

    // Function to perform a swipe
    fun performSwipe(startX: Int, startY: Int, endX: Int, endY: Int, duration: Long) {
        val path = Path()
        path.moveTo(startX.toFloat(), startY.toFloat())
        path.lineTo(endX.toFloat(), endY.toFloat())

        val stroke = StrokeDescription(path, 0, duration)
        val gesture = Builder().addStroke(stroke).build()
        
        dispatchGesture(gesture, null, null)
    }
}