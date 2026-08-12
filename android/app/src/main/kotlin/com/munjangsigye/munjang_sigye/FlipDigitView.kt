package com.munjangsigye.munjang_sigye

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.util.AttributeSet
import android.view.Gravity
import android.view.View
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.widget.TextView

/**
 * A single flip-clock digit. Mimics the classic split-flap flip by rotating
 * around its horizontal center (rotationX) out to 90 degrees ("folding
 * away" edge-on), swapping to the new digit at that invisible midpoint,
 * then back in from -90 to 0. Real split-flap clocks use two independent
 * physical card halves; this single-view rotation reads the same to the
 * eye at clock-digit size without that extra layout complexity.
 *
 * A plain TextView (not a box with the glyph centered inside) so its own
 * measured bounds wrap tightly around the glyph — that's what lets a
 * sibling label (AM/PM) line up exactly with this digit's real on-screen
 * corner instead of an oversized box's corner.
 */
class FlipDigitView(context: Context, attrs: AttributeSet? = null) : TextView(context, attrs) {

    private var current: Char = ' '

    init {
        gravity = Gravity.CENTER
        setTextColor(Color.parseColor("#F2ECE0"))
        // Monospace: every digit occupies the same width, which is why it's
        // the typeface clocks/timers/stopwatches reach for — digits don't
        // visually shift the layout as they change (a proportional font's
        // "1" is narrower than its "8").
        typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
        includeFontPadding = false
        cameraDistance = 16000f * resources.displayMetrics.density
        // A stable hardware layer for the duration of each flip keeps this
        // view's own rasterization from being coupled with its neighbors'
        // (the colon in particular) during the rotationX animation.
        setLayerType(View.LAYER_TYPE_HARDWARE, null)
    }

    // Pins this view's measured width so swapping its digit (the text
    // change at the flip's midpoint) can never trigger a layout pass on
    // the row — only the rotationX draw transform should move, never the
    // glyph's own box. Without this, a monospace font that isn't *exactly*
    // pixel-identical per glyph on a given device could nudge the row's
    // width by a pixel each flip, which reads as the colons "drifting".
    // Widest of 0-9 (not just the current digit) so it can't be too narrow
    // for whatever digit lands here next.
    fun lockWidth() {
        var maxWidth = 0f
        for (c in '0'..'9') {
            maxWidth = maxOf(maxWidth, paint.measureText(c.toString()))
        }
        layoutParams?.let {
            it.width = kotlin.math.ceil(maxWidth.toDouble()).toInt() + paddingLeft + paddingRight
            layoutParams = it
        }
    }

    fun setDigit(digit: Char, animate: Boolean) {
        if (digit == current) return
        current = digit
        if (!animate || text.isEmpty()) {
            text = digit.toString()
            rotationX = 0f
            return
        }
        val flipOut = ObjectAnimator.ofFloat(this, "rotationX", 0f, 90f).apply {
            duration = 180
            interpolator = AccelerateInterpolator()
        }
        flipOut.addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                text = digit.toString()
                rotationX = -90f
                ObjectAnimator.ofFloat(this@FlipDigitView, "rotationX", -90f, 0f).apply {
                    duration = 180
                    interpolator = DecelerateInterpolator()
                }.start()
            }
        })
        flipOut.start()
    }
}
