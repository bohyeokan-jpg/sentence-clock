package com.munjangsigye.munjang_sigye

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

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

    // Fires whenever the user resizes this widget on their home screen, so
    // the quote can show more or fewer lines instead of staying clipped at
    // whatever size it was first placed at.
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
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)

        // More vertical room -> more lines of the quote get to show instead
        // of being clipped, with a slightly bigger font so a taller tile
        // doesn't just look like empty space was left over.
        val (maxLines, textSizeSp) = when {
            heightDp < 80 -> 1 to 10f
            heightDp < 150 -> 3 to 11f
            else -> 6 to 12.5f
        }

        // The clock itself is a native AnalogClock (see widget_medium.xml) —
        // it ticks on its own, no data or per-update work needed here.
        val views = RemoteViews(context.packageName, R.layout.widget_medium).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setTextViewText(R.id.widget_quote, quote)
            setTextViewTextSize(R.id.widget_quote, TypedValue.COMPLEX_UNIT_SP, textSizeSp)
            setInt(R.id.widget_quote, "setMaxLines", maxLines)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
