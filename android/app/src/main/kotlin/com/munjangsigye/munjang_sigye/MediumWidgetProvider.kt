package com.munjangsigye.munjang_sigye

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

class MediumWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId -> apply(context, appWidgetManager, widgetId, widgetData) }
    }

    // Resizing the widget still needs a fresh RemoteViews to pick up the
    // alarm hand / click intent again, but the quote's own font size no
    // longer needs any help here — widget_quote is autoSizeTextType=uniform
    // in a bounded (0dp+weight) box now, so it re-shrinks to fit on its own
    // whenever its bounds change, including on resize.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        apply(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun apply(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val quote = widgetData.getString("widget_quote", null) ?: "문장을 불러오는 중이에요"

        // The clock itself is a native AnalogClock (see widget_medium.xml) —
        // it ticks on its own, no data or per-update work needed here.
        val views = RemoteViews(context.packageName, R.layout.widget_medium).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setTextViewText(R.id.widget_quote, quote)
            setTextViewText(
                R.id.widget_meridiem_top,
                if (Calendar.getInstance().get(Calendar.AM_PM) == Calendar.AM) "A" else "P",
            )
            applyAlarmHand(this, widgetData)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
