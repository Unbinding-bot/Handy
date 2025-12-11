// android/app/src/main/kotlin/com/handy/OverlayManager.kt

package com.handy

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import com.handy.R // This is needed to reference your layouts/drawables

class OverlayManager(private val context: Context) {

    private var windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private val cursorSize = 80 // Size in pixels for the cursor

    // Parameters for the system window
    private val params = WindowManager.LayoutParams(
        cursorSize,
        cursorSize,
        // Determine the correct window type based on Android version
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        },
        // IMPORTANT: FLAG_NOT_FOCUSABLE and FLAG_NOT_TOUCHABLE are essential 
        // to allow touches to pass through the cursor to the underlying app.
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE 
        or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE 
        or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.START or Gravity.TOP
        x = 0
        y = 0
    }
    
    // --- Public Methods ---

    fun showOverlay() {
        if (overlayView == null) {
            // NOTE: You must have a layout file named 'cursor_overlay.xml' 
            // and an ImageView with ID 'cursor_image' in your resources.
            overlayView = LayoutInflater.from(context).inflate(R.layout.cursor_overlay, null)
            try {
                windowManager.addView(overlayView, params)
            } catch (e: WindowManager.BadTokenException) {
                // This usually happens if the permission is not granted
                e.printStackTrace()
            }
        }
    }

    fun hideOverlay() {
        if (overlayView != null) {
            windowManager.removeView(overlayView)
            overlayView = null
        }
    }

    fun updatePosition(x: Int, y: Int) {
        if (overlayView != null) {
            params.x = x - (cursorSize / 2) // Center the cursor on the coordinate
            params.y = y - (cursorSize / 2)
            windowManager.updateViewLayout(overlayView, params)
        }
    }
    
    fun isVisible(): Boolean = overlayView != null
}