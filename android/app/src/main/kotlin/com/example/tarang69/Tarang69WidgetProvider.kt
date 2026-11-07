package com.example.tarang69

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class Tarang69WidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val subject = widgetData.getString("subject_name", "ไม่มีคาบเรียน")
                val room = widgetData.getString("subject_room", "-")
                val time = widgetData.getString("subject_time", "พักผ่อน")
                val status = widgetData.getString("status_badge", "TARANG69")
                val next = widgetData.getString("next_subject", "-")
                val day = widgetData.getString("day_name", "ม.6/9")

                setTextViewText(R.id.widget_subject_name, subject)
                setTextViewText(R.id.widget_subject_room, "📍 $room")
                setTextViewText(R.id.widget_subject_time, time)
                setTextViewText(R.id.widget_status_badge, status)
                setTextViewText(R.id.widget_next_subject, next)
                setTextViewText(R.id.widget_day_name, day)

                // Launch app when tapping anywhere on widget
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
