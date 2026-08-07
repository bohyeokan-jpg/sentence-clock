package com.munjangsigye.munjang_sigye

import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews

/**
 * Rotates the shared widget_clock_hand_alarm ImageView (see widget_medium.xml
 * / widget_large.xml) to point at the set alarm time, or hides it entirely
 * when the alarm is off. Both providers stack this ImageView directly on top
 * of their AnalogClock at identical bounds, so rotating it around its own
 * center (View's default pivot) lines it up with that clock's hands.
 *
 * Same angle convention as the hour hand: combined hour+minute position,
 * not just the hour — see AnalogClockPainter (Dart) for the in-app version
 * this mirrors.
 */
fun applyAlarmHand(views: RemoteViews, widgetData: SharedPreferences) {
    val enabled = widgetData.getBoolean("widget_alarm_enabled", false)
    if (!enabled) {
        views.setViewVisibility(R.id.widget_clock_hand_alarm, View.GONE)
        return
    }
    val hour = widgetData.getInt("widget_alarm_hour", 0)
    val minute = widgetData.getInt("widget_alarm_minute", 0)
    val angle = ((hour % 12) + minute / 60f) / 12f * 360f
    views.setViewVisibility(R.id.widget_clock_hand_alarm, View.VISIBLE)
    views.setFloat(R.id.widget_clock_hand_alarm, "setRotation", angle)
}
