package com.munjangsigye.munjang_sigye

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

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
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 300)

        // The quote's own font size no longer needs any help here —
        // widget_quote is autoSizeTextType=uniform in a bounded (0dp+weight)
        // box now, so it re-shrinks to fit on its own (including on
        // resize). The attribution line is small and fixed-size, so it's
        // still worth hiding entirely below a height where it'd just get
        // squeezed out anyway.
        val showAttribution = heightDp >= 180

        // The clock itself is a native AnalogClock (see widget_large.xml) —
        // it ticks on its own, no data or per-update work needed here.
        val views = RemoteViews(context.packageName, R.layout.widget_large).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setTextViewText(R.id.widget_quote, quote)
            setTextViewText(R.id.widget_attribution, attribution)
            setTextViewText(
                R.id.widget_meridiem,
                if (Calendar.getInstance().get(Calendar.AM_PM) == Calendar.AM) "AM" else "PM",
            )
            setViewVisibility(R.id.widget_attribution, if (showAttribution) View.VISIBLE else View.GONE)
            applyAlarmHand(this, widgetData)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
