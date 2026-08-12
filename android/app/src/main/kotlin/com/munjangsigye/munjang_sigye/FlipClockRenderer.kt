package com.munjangsigye.munjang_sigye

import android.content.Context
import android.graphics.SurfaceTexture
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.Surface
import android.view.TextureView
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

private const val TAG = "FlipClockRenderer"

/**
 * All the flip-clock rendering logic (digits, background video, alarm
 * badge, ticking) for `res/layout/dream_flip_clock.xml`, factored out of
 * [FlipClockDreamService] so the exact same visual can also run inside a
 * plain [android.app.Activity] — [DreamPreviewActivity] uses this to give
 * an in-app "미리보기 실행" button, without duplicating any of the setup.
 *
 * [context] just needs to be usable for `resources`/`packageName`/raw
 * resource file descriptors — both a Service and an Activity qualify.
 * [root] must already be the inflated `dream_flip_clock.xml` (i.e. the
 * caller has already called `setContentView`/`inflate`).
 */
class FlipClockRenderer(private val context: Context, private val root: View) {

    private lateinit var digitViews: List<FlipDigitView>
    private lateinit var meridiemView: TextView
    private var backgroundPlayer: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())
    private var tickRunnable: Runnable? = null

    private fun <T : View> find(id: Int): T = root.findViewById(id)

    private var backgroundRawRes: Int? = null
    private var layoutListenerAttached = false

    // Each piece is its own try/catch so one failing (most likely the video
    // — it's the newest, heaviest, most device-dependent part) can't take
    // the whole clock down with it. Before this, any exception anywhere in
    // here escaped all the way out of onCreate/onAttachedToWindow, which
    // is what surfaced on-device as the *whole screen* going black and
    // dropping out — Android's standard response to an activity/service
    // crashing during setup, not something we did intentionally.
    //
    // One-time setup (digit view list, starting the video player, the
    // ticking clock) happens here. Everything that depends on root's
    // *actual* pixel size — digit text size, the background's swapped
    // LayoutParams+rotation, clock_content's pivot+rotation — is pulled out
    // into applyLayout() and re-run every time root's layout size actually
    // changes (addOnLayoutChangeListener), not just once. A single
    // best-effort read (root.post, one frame) turned out to still be too
    // early on-device: a plain Activity's window can take more than one
    // layout pass to settle into its final fullscreen/immersive bounds, and
    // reading root.width/height mid-transition reproduced the exact same
    // clipped/misaligned symptom the *displayMetrics* version had, just
    // from a different stale value. Re-running on every real size change
    // means whichever pass turns out to be the final one is the one that
    // sticks — and it doubles as the fix for live device rotation while the
    // preview is open, which was reading as "portrait and landscape show it
    // backwards from each other": before this, isPortrait/root.width/height
    // were only ever read once at the very start, so rotating the device
    // afterward never updated anything — the view was frozen in whatever
    // state it first rendered in, which necessarily looks "wrong" for
    // whichever orientation you rotate *into*.
    fun start() {
        runCatching { startBackgroundVideo() }
            .onFailure { Log.e(TAG, "startBackgroundVideo failed", it) }

        runCatching {
            digitViews = listOf(
                find(R.id.digit_h1),
                find(R.id.digit_h2),
                find(R.id.digit_m1),
                find(R.id.digit_m2),
                find(R.id.digit_s1),
                find(R.id.digit_s2),
            )
            meridiemView = find(R.id.dream_meridiem)

            renderTime(animate = false)
            scheduleTicks()
        }.onFailure { Log.e(TAG, "clock digits failed", it) }

        runCatching { showAlarmBadge() }
            .onFailure { Log.e(TAG, "showAlarmBadge failed", it) }

        runCatching { showQuote() }
            .onFailure { Log.e(TAG, "showQuote failed", it) }

        if (!layoutListenerAttached) {
            layoutListenerAttached = true
            root.addOnLayoutChangeListener { _, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
                if (right - left != oldRight - oldLeft || bottom - top != oldBottom - oldTop) {
                    applyLayout()
                }
            }
        }
        applyLayout()
    }

    private fun applyLayout() {
        if (root.width <= 0 || root.height <= 0) return

        runCatching { sizeClock() }
            .onFailure { Log.e(TAG, "sizeClock failed", it) }

        runCatching { resizeBackgroundContainer() }
            .onFailure { Log.e(TAG, "resizeBackgroundContainer failed", it) }

        // clock_content is [meridiem above, digit_row below] in plain
        // document flow, so its own geometric center isn't digit_row's
        // center (meridiem's height pulls it down) — layout_gravity="center"
        // alone would leave the *digits* off-center by roughly half of
        // meridiem's height. Nudging by translation (no rotation involved
        // now that everything renders upright) puts digit_row's actual
        // center on the screen's true center instead.
        runCatching {
            val clockContent = find<LinearLayout>(R.id.clock_content)
            val digitRow = find<LinearLayout>(R.id.digit_row)
            clockContent.post {
                runCatching {
                    val pivotX = digitRow.left + digitRow.width / 2f
                    val pivotY = digitRow.top + digitRow.height / 2f
                    clockContent.translationX = clockContent.width / 2f - pivotX
                    clockContent.translationY = clockContent.height / 2f - pivotY
                }.onFailure { Log.e(TAG, "clock_content centering failed", it) }
            }
        }.onFailure { Log.e(TAG, "clock_content setup failed", it) }
    }

    fun stop() {
        tickRunnable?.let { handler.removeCallbacks(it) }
        tickRunnable = null
        backgroundPlayer?.release()
        backgroundPlayer = null
    }

    // Reads widget_dream_background (pushed by
    // DreamBackgroundNotifier/WidgetSyncService.syncDreamBackground when
    // the user picks one in Settings > 화면보호기 배경) to decide which
    // res/raw/*.mp4 to play, or none at all — same read-once-at-start
    // convention as showAlarmBadge(). All videos are Pixabay Content
    // License, free/rights-free use.
    //
    // MediaPlayer + TextureView, not VideoView — VideoView is built on
    // SurfaceView, which opens its own separate compositor window that the
    // WindowManager needs to Z-order correctly against the rest of the
    // screen; a Daydream's window (TYPE_DREAM) doesn't reliably get that
    // set up, which is what surfaced on-device as "동영상을 재생할 수
    // 없습니다" (can't play this video) right as the screen saver started.
    // TextureView instead renders into an ordinary View inside the normal
    // view hierarchy — no separate window, so that whole class of problem
    // doesn't apply (and it's why this same class works unmodified inside
    // a plain Activity too).
    //
    private fun startBackgroundVideo() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val backgroundId = widgetData.getString("widget_dream_background", "none")
        val rawRes = when (backgroundId) {
            "ocean" -> R.raw.ocean_waves
            "space" -> R.raw.space_stars
            "sky" -> R.raw.clear_sky
            "beach" -> R.raw.beach
            else -> null
        }
        backgroundRawRes = rawRes
        if (rawRes == null) {
            find<FrameLayout>(R.id.background_container).visibility = View.GONE
            return
        }

        val textureView = find<TextureView>(R.id.dream_background_video)
        textureView.surfaceTextureListener = object : TextureView.SurfaceTextureListener {
            override fun onSurfaceTextureAvailable(surfaceTexture: SurfaceTexture, width: Int, height: Int) {
                val player = MediaPlayer()
                backgroundPlayer = player
                player.setSurface(Surface(surfaceTexture))
                player.setVolume(0f, 0f)
                player.isLooping = true
                val afd = context.resources.openRawResourceFd(rawRes)
                player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                player.setOnPreparedListener { it.start() }
                // No logcat access while debugging this remotely (same
                // constraint as DreamPreviewActivity's step Toasts) — without
                // this, a MediaPlayer failure (e.g. running out of storage
                // buffering the 33.6MB beach.mp4 on a low-storage device)
                // just silently leaves the dark background showing with no
                // signal of why the video never appeared.
                player.setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "background video error what=$what extra=$extra")
                    Toast.makeText(context, "배경 영상 재생 실패 (what=$what, extra=$extra)", Toast.LENGTH_LONG).show()
                    true
                }
                player.prepareAsync()
            }

            override fun onSurfaceTextureSizeChanged(surfaceTexture: SurfaceTexture, width: Int, height: Int) = Unit

            override fun onSurfaceTextureDestroyed(surfaceTexture: SurfaceTexture): Boolean {
                backgroundPlayer?.release()
                backgroundPlayer = null
                return true
            }

            override fun onSurfaceTextureUpdated(surfaceTexture: SurfaceTexture) = Unit
        }
    }

    private fun resizeBackgroundContainer() {
        val rawRes = backgroundRawRes ?: return
        val container = find<FrameLayout>(R.id.background_container)
        container.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        )
        container.rotation = 0f
        // rawRes itself isn't used here — it's only read to confirm a
        // background is actually selected (container stays GONE otherwise,
        // set once in startBackgroundVideo(), never touched again here).
    }

    // All six digits share one size — h/m/s all need to be equally
    // readable, not just equally present — sized off the screen's own
    // short side so it scales with whatever phone this runs on. Colons get
    // half that, just for proportion against the digits.
    private fun sizeClock() {
        // root.width/height (this window's actual current bounds), not
        // resources.displayMetrics — see the note on start()/root.post.
        val shortSide = minOf(root.width, root.height).toFloat()
        val digitSizePx = shortSide * 0.26f * 0.85f
        val colonSizePx = digitSizePx * 0.5f

        // Widths are locked right after sizing (not left as wrap_content)
        // so the digit flip's text swap — new glyph in place of the old —
        // can never nudge the row's layout even by a pixel. Left as
        // wrap_content, that pixel-level nudge is what read as the colons
        // "drifting" each time a digit flipped.
        digitViews.forEach {
            it.setTextSize(TypedValue.COMPLEX_UNIT_PX, digitSizePx)
            it.lockWidth()
        }
        val colon1 = find<TextView>(R.id.colon1)
        val colon2 = find<TextView>(R.id.colon2)
        for (colon in listOf(colon1, colon2)) {
            colon.setTextSize(TypedValue.COMPLEX_UNIT_PX, colonSizePx)
            val width = kotlin.math.ceil(colon.paint.measureText(":").toDouble()).toInt() +
                colon.paddingLeft + colon.paddingRight
            colon.layoutParams = colon.layoutParams.also { it.width = width }
        }
    }

    // Reads the same widget_alarm_* keys the home-screen widgets' red alarm
    // hand reads (see AlarmHandView.kt) — WidgetSyncService.syncAlarm()
    // pushes these from the app's alarm settings, so no separate plumbing
    // is needed for the dream to know about it. Read once at start (a
    // daydream/preview is a fresh instance each time it starts, so this
    // can't go stale during a single showing) rather than kept live.
    // Always visible (on or off) so the state itself — not just its
    // absence — is legible at a glance: a plain bell when the alarm is
    // set, a crossed-out bell when it isn't.
    private fun showAlarmBadge() {
        val badge = find<TextView>(R.id.dream_alarm_badge)
        val density = context.resources.displayMetrics.density
        val lp = badge.layoutParams as FrameLayout.LayoutParams
        badge.rotation = 0f
        lp.gravity = Gravity.TOP or Gravity.END
        lp.bottomMargin = 0
        lp.topMargin = (18 * density).toInt()
        lp.marginEnd = (18 * density).toInt()
        badge.layoutParams = lp
        badge.visibility = View.VISIBLE

        val widgetData = HomeWidgetPlugin.getData(context)
        val enabled = widgetData.getBoolean("widget_alarm_enabled", false)
        if (!enabled) {
            badge.text = "🔕" // 🔕 bell with cancellation stroke
            return
        }
        val hour24 = widgetData.getInt("widget_alarm_hour", 0)
        val minute = widgetData.getInt("widget_alarm_minute", 0)
        val meridiem = if (hour24 < 12) "AM" else "PM"
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        badge.text = "🔔 %s %d:%02d".format(meridiem, hour12, minute) // 🔔
    }

    // Same widget_quote/widget_attribution keys the home-screen widgets read
    // (see LargeWidgetProvider.kt) — QuoteNotifier.syncQuote() pushes these
    // whenever the quote changes, so no separate plumbing is needed for the
    // dream to know about it. Read once at start, same convention as
    // showAlarmBadge(). widget_quote already comes wrapped in literal quote
    // marks (added on the Dart side) — used as-is, matching the widgets.
    private fun showQuote() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val quoteView = find<TextView>(R.id.dream_quote)
        val attributionView = find<TextView>(R.id.dream_attribution)

        quoteView.text = widgetData.getString("widget_quote", null) ?: "오늘의 문장을 준비하고 있어요."

        val attribution = widgetData.getString("widget_attribution", null)
        if (attribution.isNullOrEmpty()) {
            attributionView.visibility = View.GONE
        } else {
            attributionView.visibility = View.VISIBLE
            attributionView.text = attribution
        }
    }

    private fun scheduleTicks() {
        val runnable = Runnable {
            renderTime(animate = true)
            val delay = 1000L - (Calendar.getInstance().get(Calendar.MILLISECOND))
            tickRunnable?.let { handler.postDelayed(it, delay) }
        }
        tickRunnable = runnable
        handler.post(runnable)
    }

    private fun renderTime(animate: Boolean) {
        val cal = Calendar.getInstance()
        val hour24 = cal.get(Calendar.HOUR_OF_DAY)
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val minute = cal.get(Calendar.MINUTE)
        val second = cal.get(Calendar.SECOND)

        meridiemView.text = if (hour24 < 12) "AM" else "PM"

        val digits = "%02d%02d%02d".format(hour12, minute, second)
        digits.forEachIndexed { index, c -> digitViews[index].setDigit(c, animate) }
    }
}
