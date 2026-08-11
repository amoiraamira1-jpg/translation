package com.example.screen_translator

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

/**
 * Invisible activity whose only job is to pop the system "Start recording
 * or casting?" dialog and forward the resulting token to OverlayService,
 * which uses it to grab a single screenshot. Finishes itself immediately
 * after.
 */
class ScreenCaptureActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE) {
            val intent = Intent(this, OverlayService::class.java).apply {
                action = OverlayService.ACTION_CAPTURE_GRANTED
                putExtra(OverlayService.EXTRA_RESULT_CODE, resultCode)
                putExtra(OverlayService.EXTRA_RESULT_DATA, data)
            }
            startForegroundService(intent)
        }
        finish()
        overridePendingTransition(0, 0)
    }

    companion object {
        private const val REQUEST_CODE = 4201
    }
}
