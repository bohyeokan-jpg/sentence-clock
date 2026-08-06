package com.munjangsigye.munjang_sigye

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MediumWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        // Flutter pushes the quote and a rendered clock-face image whenever
        // the quote changes (WidgetSyncService); the widget just re-displays
        // whatever was pushed last, it never picks or draws its own. The
        // digital time next to it is a native TextClock and needs no data.
        val quote = widgetData.getString("widget_quote", null) ?: "문장을 불러오는 중이에요"
        val clockImagePath = widgetData.getString("widget_clock_image", null)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_medium).apply {
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setTextViewText(R.id.widget_quote, quote)
                clockImagePath
                    ?.let { BitmapFactory.decodeFile(it) }
                    ?.let { setImageViewBitmap(R.id.widget_clock_image, it) }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
