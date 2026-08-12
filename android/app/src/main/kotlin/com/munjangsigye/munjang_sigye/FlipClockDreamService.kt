package com.munjangsigye.munjang_sigye

import android.service.dreams.DreamService

/**
 * Fullscreen flip-clock screensaver. Registered as an Android Daydream (see
 * AndroidManifest.xml + res/xml/flip_clock_dream_info.xml), so it's offered
 * automatically in Settings > Display > Screen saver and runs while the
 * device is docked/charging and idle — the closest a regular third-party
 * app can get to "show a clock when the screen would otherwise turn off",
 * since true Always-On-Display while the screen is fully powered down is a
 * system/OEM-level feature (e.g. Samsung's AOD) that isn't exposed to
 * ordinary apps.
 *
 * All the actual rendering (digits, rotation, background video, alarm
 * badge) lives in [FlipClockRenderer] — shared with [DreamPreviewActivity]
 * so the in-app "미리보기 실행" button shows exactly this, not a
 * reimplementation that could drift out of sync.
 */
class FlipClockDreamService : DreamService() {

    private var renderer: FlipClockRenderer? = null

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()

        isInteractive = false
        isFullscreen = true

        setContentView(R.layout.dream_flip_clock)
        val root = findViewById<android.view.View>(R.id.dream_root)
        renderer = FlipClockRenderer(this, root).also { it.start() }
    }

    override fun onDetachedFromWindow() {
        renderer?.stop()
        renderer = null
        super.onDetachedFromWindow()
    }
}
