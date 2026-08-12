package com.example.screen_translator

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.view.MotionEvent
import android.view.View

/**
 * Full-screen transparent view used only while "Region Mode" is active.
 * The user drags out a rectangle; on release [onSelected] fires with the
 * selected screen rect so OverlayService can crop the capture to it.
 */
class RegionSelectView(
    context: Context,
    private val onSelected: (Rect) -> Unit,
) : View(context) {

    private var startX = 0; private var startY = 0
    private var curX = 0; private var curY = 0
    private var active = false

    private val fillPaint = Paint().apply { color = Color.parseColor("#552196F3") }
    private val strokePaint = Paint().apply {
        color = Color.parseColor("#2196F3"); style = Paint.Style.STROKE; strokeWidth = 4f
    }
    private val dimPaint = Paint().apply { color = Color.parseColor("#66000000") }

    fun begin(anchorX: Int, anchorY: Int) {
        startX = anchorX; startY = anchorY; curX = anchorX; curY = anchorY
        active = true
        invalidate()
    }

    fun updateCurrent(x: Int, y: Int) {
        curX = x; curY = y
        invalidate()
    }

    fun finishSelection() {
        active = false
        val rect = Rect(
            minOf(startX, curX), minOf(startY, curY),
            maxOf(startX, curX), maxOf(startY, curY)
        )
        if (rect.width() > 20 && rect.height() > 20) onSelected(rect)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        // Region selection is normally driven by the floating icon's own
        // touch handler forwarding coordinates via updateCurrent()/
        // finishSelection(); this override just keeps the view eligible to
        // receive touches if it is ever driven directly.
        when (event.action) {
            MotionEvent.ACTION_MOVE -> updateCurrent(event.rawX.toInt(), event.rawY.toInt())
            MotionEvent.ACTION_UP -> finishSelection()
        }
        return true
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), dimPaint)
        if (!active) return
        val rect = Rect(minOf(startX, curX), minOf(startY, curY), maxOf(startX, curX), maxOf(startY, curY))
        canvas.drawRect(rect, fillPaint)
        canvas.drawRect(rect, strokePaint)
    }
}
