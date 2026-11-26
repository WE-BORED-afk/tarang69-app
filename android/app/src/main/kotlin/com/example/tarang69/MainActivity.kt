package com.example.tarang69

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
        private const val EXACT_ALARM_CHANNEL = "com.example.tarang69/exact_alarm"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXACT_ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canScheduleExactAlarms" -> {
                        val canExact = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                            true
                        } else {
                            val alarmManager =
                                getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                            alarmManager?.canScheduleExactAlarms() ?: false
                        }
                        result.success(canExact)
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val pkgUri = Uri.parse("package:$packageName")
                            try {
                                startActivity(
                                    Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                        data = pkgUri
                                    }
                                )
                            } catch (_: Exception) {
                                try {
                                    startActivity(
                                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkgUri)
                                    )
                                } catch (_: Exception) {
                                }
                            }
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
