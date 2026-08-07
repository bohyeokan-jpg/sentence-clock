package com.munjangsigye.munjang_sigye

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class LargeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            apply(context, appWidgetManager, widgetId, widgetData, appWidgetManager.getAppWidgetOptions(widgetId))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        apply(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context), newOptions)
    }

    private fun apply(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
        options: Bundle,
    ) {
        val quote = widgetData.getString("widget_quote", null) ?: "문장을 불러오는 중이에요"
        val attribution = widgetData.getString("widget_attribution", null) ?: ""
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 260)

        // Same idea as the medium widget: a taller tile shows more of the
        // quote (and eventually the attribution line) instead of clipping
        // it, rather than leaving the extra room empty. Base sizes roughly
        // doubled from the original 13/14/16sp — the widget defaults to a
        // bigger footprint now (see widget_large_info.xml) specifically so
        // both the clock and this text could grow.
        val (maxLines, textSizeSp, showAttribution) = when {
            heightDp < 180 -> Triple(1, 26f, false)
            heightDp < 260 -> Triple(2, 30f, true)
            else -> Triple(3, 34f, true)
        }

        // The clock itself is a native AnalogClock (see widget_large.xml) —
        // it ticks on its own, no data or per-update work needed here.
        val views = RemoteViews(context.packageName, R.layout.widget_large).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setTextViewText(R.id.widget_quote, quote)
            setTextViewTextSize(R.id.widget_quote, TypedValue.COMPLEX_UNIT_SP, textSizeSp)
            setInt(R.id.widget_quote, "setMaxLines", maxLines)
            setTextViewText(R.id.widget_attribution, attribution)
            setViewVisibility(R.id.widget_attribution, if (showAttribution) View.VISIBLE else View.GONE)
            applyAlarmHand(this, widgetData)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
