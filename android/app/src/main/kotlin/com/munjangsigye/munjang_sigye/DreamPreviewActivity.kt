package com.munjangsigye.munjang_sigye

import android.app.Activity
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Toast

private const val TAG = "DreamPreviewActivity"

/**
 * Fullscreen in-app run of the flip-clock screen saver, launched from
 * Settings > "화면보호기 실행" in the Flutter app (see MainActivity's
 * `openDreamPreview` channel method) — lets the user see it without going
 * through Settings > Display > Screen saver each time. Reuses
 * [FlipClockRenderer] verbatim, so this is guaranteed to look exactly like
 * the real [FlipClockDreamService], not a separate reimplementation that
 * could drift out of sync.
 *
 * Unlike the real dream, this is a normal Activity — there's no system
 * "tap to dismiss" behavior, so tapping anywhere or pressing back just
 * finishes it (default Activity back behavior already does the latter).
 */
class DreamPreviewActivity : Activity() {

    private var renderer: FlipClockRenderer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Split into individually-caught steps (not one big try/catch) so
        // the Toast itself says *which* step failed — there's no logcat
        // access while debugging this remotely, so the on-screen message
        // is the only diagnostic available. An uncaught exception here
        // used to escape onCreate entirely, which Android answers by
        // tearing this Activity down immediately — on-device that showed
        // up as the whole screen going black and dropping back out right
        // as the button was pressed.
        // Found via the step-by-step Toasts: window.insetsController?.hide(...)
        // (the API 30+ way to hide the nav bar) threw a NullPointerException
        // *inside the framework's own call*, on at least one real device —
        // the `?.` guard only protects against insetsController itself being
        // null, not whatever it dereferences internally. Dropped in favor of
        // the older systemUiVisibility flags, which work the same on every
        // API level this app supports (minSdk 26) and didn't hit this.
        // Non-fatal on its own (wrapped separately, doesn't finish() on
        // failure) since hiding the nav bar is cosmetic — worth losing
        // immersive mode over, not worth losing the whole preview over.
        step("창 설정") {
            @Suppress("DEPRECATION")
            window.setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
            )
        }
        step("전체화면 몰입 모드") {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                )
        }

        var root: View? = null
        if (!step("화면 그리기") {
                setContentView(R.layout.dream_flip_clock)
                root = findViewById(R.id.dream_root)
            }
        ) {
            finish(); return
        }

        val r = root
        if (r == null) {
            Toast.makeText(this, "화면 그리기: dream_root를 못 찾음", Toast.LENGTH_LONG).show()
            finish(); return
        }

        step("탭으로 닫기 연결") { r.setOnClickListener { finish() } }

        // FlipClockRenderer.start() defers its own dimension-dependent
        // setup internally (root.post) precisely because a plain Activity's
        // window isn't guaranteed to have settled into its final
        // fullscreen/immersive size the instant this line runs — no need
        // to duplicate that deferral here too.
        step("시계 그리기 시작") { renderer = FlipClockRenderer(this, r).also { it.start() } }
    }

    /** Runs [block], logs + Toasts `"$label 실패: ${e.message}"` on failure, returns whether it succeeded. */
    private inline fun step(label: String, block: () -> Unit): Boolean {
        return try {
            block()
            true
        } catch (t: Throwable) {
            Log.e(TAG, "$label failed", t)
            Toast.makeText(this, "$label 실패: ${t.message}", Toast.LENGTH_LONG).show()
            false
        }
    }

    override fun onDestroy() {
        renderer?.stop()
        renderer = null
        super.onDestroy()
    }
}
