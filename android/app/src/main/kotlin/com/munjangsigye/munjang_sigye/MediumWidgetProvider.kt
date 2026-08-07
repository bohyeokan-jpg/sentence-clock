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
        appWidgetIds.forEach { widgetId ->
            apply(context, appWidgetManager, widgetId, widgetData, appWidgetManager.getAppWidgetOptions(widgetId))
        }
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

        // Taller-than-wide box (user dragged the widget into a vertical
        // shape) switches to widget_medium_vertical.xml — clock+time row on
        // top, quote spanning the full width below — instead of the default
        // side-by-side split, which gets cramped in a narrow column.
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val layoutRes = if (height > width) R.layout.widget_medium_vertical else R.layout.widget_medium

        // The clock itself is a native AnalogClock (see widget_medium.xml /
        // widget_medium_vertical.xml) — it ticks on its own, no data or
        // per-update work needed here.
        val views = RemoteViews(context.packageName, layoutRes).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setTextViewText(R.id.widget_quote, quote)
            setTextViewText(
                R.id.widget_meridiem,
                if (Calendar.getInstance().get(Calendar.AM_PM) == Calendar.AM) "AM" else "PM",
            )
            applyAlarmHand(this, widgetData)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
