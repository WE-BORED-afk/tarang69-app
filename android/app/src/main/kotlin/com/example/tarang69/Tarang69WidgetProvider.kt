package com.example.tarang69

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class Tarang69WidgetProvider : HomeWidgetProvider() {
    companion object {
        const val ACTION_WIDGET_REFRESH = "com.example.tarang69.ACTION_WIDGET_REFRESH"
        private const val ACTION_EXACT_ALARM_CHANGED =
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"
        private const val SCHEDULE_ASSET_PATH = "flutter_assets/assets/data/schedule.json"
        private const val TRANSITION_BUFFER_MS = 500L
        private const val FALLBACK_REFRESH_INTERVAL_MS = 5 * 60_000L
        private const val ALARM_REQUEST_CODE = 6901
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_WIDGET_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            ACTION_EXACT_ALARM_CHANGED -> {
                updateAllWidgets(context)
            }
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelRefreshAlarm(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        if (appWidgetIds.isEmpty()) {
            val activeIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, Tarang69WidgetProvider::class.java)
            )
            if (activeIds.isEmpty()) {
                cancelRefreshAlarm(context)
            }
            return
        }

        val nowMillis = System.currentTimeMillis()
        val simulatedActive = widgetData.getBoolean("simulated_active", false)
        val computed = if (!simulatedActive) {
            val planId = widgetData.getString("selected_plan_id", "plan1") ?: "plan1"
            val cachedJson = widgetData.getString("schedule_json", null)?.takeIf { it.isNotBlank() }
            WidgetScheduleCalculator.calculate(cachedJson, planId, nowMillis)
                ?: WidgetScheduleCalculator.calculate(loadBundledScheduleJson(context), planId, nowMillis)
        } else {
            null
        }

        val subject = computed?.subjectName
            ?: widgetData.getString("subject_name", "TARANG69")
            ?: "TARANG69"
        val time = computed?.timeStr
            ?: widgetData.getString("subject_time", "พักผ่อน")
            ?: "พักผ่อน"
        val statusBadgeText = computed?.statusBadge
            ?: widgetData.getString("status_badge", "ม.6/9")
            ?: "ม.6/9"
        val next = computed?.nextSubject
            ?: widgetData.getString("next_subject", "-")
            ?: "-"
        val day = computed?.dayName
            ?: widgetData.getString("day_name", "ม.6/9")
            ?: "ม.6/9"
        val countdown = computed?.countdownText
            ?: widgetData.getString("countdown_text", "⏱ ตารางเรียน")
            ?: "⏱ ตารางเรียน"
        val later = computed?.laterSubject
            ?: widgetData.getString("later_subject", "")
            ?: ""

        val canExact = canScheduleExact(context)
        val liveStatus = if (!simulatedActive &&
            computed != null &&
            computed.isLiveCountdown &&
            computed.remainingMillis > 0L &&
            canExact
        ) {
            computed
        } else {
            null
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val launchPendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                setTextViewText(R.id.widget_subject_name, subject)
                setViewVisibility(R.id.widget_subject_room, View.GONE)
                setTextViewText(R.id.widget_subject_time, time)
                setTextViewText(R.id.widget_status_badge, "• $statusBadgeText")
                setTextViewText(R.id.widget_next_subject, "คาบถัดไป: $next")
                setTextViewText(R.id.widget_day_name, day)

                if (liveStatus != null) {
                    val base = SystemClock.elapsedRealtime() + liveStatus.remainingMillis
                    val format = if (liveStatus.isBeforeSchool) "⏱ เริ่ม %s" else "⏱ เหลือ %s"
                    setChronometerCountDown(R.id.widget_chronometer, true)
                    setChronometer(R.id.widget_chronometer, base, format, true)
                    setViewVisibility(R.id.widget_chronometer, View.VISIBLE)
                    setViewVisibility(R.id.widget_countdown_badge, View.GONE)
                } else {
                    setChronometer(R.id.widget_chronometer, SystemClock.elapsedRealtime(), null, false)
                    setViewVisibility(R.id.widget_chronometer, View.GONE)
                    setTextViewText(R.id.widget_countdown_badge, countdown)
                    setViewVisibility(R.id.widget_countdown_badge, View.VISIBLE)
                }

                if (later.isNotEmpty()) {
                    setTextViewText(R.id.widget_later_subject, later)
                    setViewVisibility(R.id.widget_expand_section_2, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_expand_section_2, View.GONE)
                }

                setOnClickPendingIntent(R.id.widget_root, launchPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        if (!simulatedActive && computed != null) {
            val nextBoundaryTrigger = computed.nextTransitionMillis + TRANSITION_BUFFER_MS
            val triggerAtMillis = if (canExact) {
                nextBoundaryTrigger
            } else {
                minOf(nextBoundaryTrigger, nowMillis + FALLBACK_REFRESH_INTERVAL_MS)
            }
            scheduleRefreshAlarm(context, triggerAtMillis, canExact)
        } else {
            cancelRefreshAlarm(context)
        }
    }

    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, Tarang69WidgetProvider::class.java)
        )
        if (widgetIds.isEmpty()) {
            cancelRefreshAlarm(context)
            return
        }
        onUpdate(context, appWidgetManager, widgetIds, HomeWidgetPlugin.getData(context))
    }

    private fun loadBundledScheduleJson(context: Context): String? {
        return try {
            context.assets.open(SCHEDULE_ASSET_PATH).bufferedReader(Charsets.UTF_8).use { it.readText() }
        } catch (_: Exception) {
            null
        }
    }

    private fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        return try {
            alarmManager.canScheduleExactAlarms()
        } catch (_: Exception) {
            false
        }
    }

    private fun buildRefreshPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, Tarang69WidgetProvider::class.java).apply {
            action = ACTION_WIDGET_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun scheduleRefreshAlarm(context: Context, triggerAtMillis: Long, canExact: Boolean) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pendingIntent = buildRefreshPendingIntent(context)
        val safeTrigger = maxOf(triggerAtMillis, System.currentTimeMillis() + 1_000L)
        try {
            if (canExact) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        safeTrigger,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, safeTrigger, pendingIntent)
                }
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        safeTrigger,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, safeTrigger, pendingIntent)
                }
            }
        } catch (_: SecurityException) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        safeTrigger,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, safeTrigger, pendingIntent)
                }
            } catch (_: Exception) {
            }
        } catch (_: Exception) {
        }
    }

    private fun cancelRefreshAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            alarmManager.cancel(buildRefreshPendingIntent(context))
        } catch (_: Exception) {
        }
    }
}
