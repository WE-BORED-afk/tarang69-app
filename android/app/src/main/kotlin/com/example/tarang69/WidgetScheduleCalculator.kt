package com.example.tarang69

import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone
import kotlin.math.ceil

data class WidgetStatus(
    val subjectName: String,
    val timeStr: String,
    val statusBadge: String,
    val nextSubject: String,
    val laterSubject: String,
    val dayName: String,
    val countdownText: String,
    val remainingMillis: Long,
    val targetEndMillis: Long,
    val nextTransitionMillis: Long,
    val isBeforeSchool: Boolean,
    val isAfterSchool: Boolean,
    val isWeekend: Boolean,
    val isLiveCountdown: Boolean
)

object WidgetScheduleCalculator {
    private data class ScheduleItem(
        val type: String,
        val period: String?,
        val code: String?,
        val name: String?,
        val title: String?
    )

    private data class ItemTimeRange(
        val start: Int,
        val end: Int,
        val timeStr: String
    )

    private val periodRegex = Regex("""(\d+)(?:\s*-\s*(\d+))?""")

    fun parsePeriodRange(period: String?): Pair<Int, Int>? {
        val match = periodRegex.find(period ?: "") ?: return null
        val start = match.groupValues[1].toInt()
        val endStr = match.groupValues[2]
        val end = if (endStr.isNotEmpty()) endStr.toInt() else start
        return Pair(start, end)
    }

    fun calculate(
        jsonString: String?,
        planId: String?,
        nowMillis: Long = System.currentTimeMillis(),
        timeZone: TimeZone = TimeZone.getDefault()
    ): WidgetStatus? {
        if (jsonString.isNullOrBlank()) return null
        val root = try {
            JSONObject(jsonString)
        } catch (_: Exception) {
            return null
        }

        val cal = Calendar.getInstance(timeZone).apply { timeInMillis = nowMillis }
        val midnightCal = (cal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nextMidnightMillis = (midnightCal.clone() as Calendar).apply {
            add(Calendar.DAY_OF_MONTH, 1)
        }.timeInMillis

        val (dayKey, dayName) = when (cal.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> "จันทร์" to "วันจันทร์"
            Calendar.TUESDAY -> "อังคาร" to "วันอังคาร"
            Calendar.WEDNESDAY -> "พุธ" to "วันพุธ"
            Calendar.THURSDAY -> "พฤหัสบดี" to "วันพฤหัสบดี"
            Calendar.FRIDAY -> "ศุกร์" to "วันศุกร์"
            Calendar.SATURDAY -> null to "วันเสาร์"
            Calendar.SUNDAY -> null to "วันอาทิตย์"
            else -> null to "วันหยุด"
        }

        if (dayKey == null) {
            return WidgetStatus(
                subjectName = "วันหยุดสุดสัปดาห์ ($dayName)",
                timeStr = "Weekend Holiday",
                statusBadge = "🎉 วันหยุด",
                nextSubject = "วันจันทร์เจอกันใหม่นะ!",
                laterSubject = "ดูตารางเรียนวันจันทร์ล่วงหน้าได้",
                dayName = dayName,
                countdownText = "🎉 วันหยุด",
                remainingMillis = 0L,
                targetEndMillis = nextMidnightMillis,
                nextTransitionMillis = nextMidnightMillis,
                isBeforeSchool = false,
                isAfterSchool = false,
                isWeekend = true,
                isLiveCountdown = false
            )
        }

        val scheduleObj = root.optJSONObject("schedule")?.optJSONObject(dayKey) ?: return null
        val bellPlansObj = root.optJSONObject("bellPlans") ?: return null
        val resolvedPlanId = if (!planId.isNullOrBlank() && bellPlansObj.has(planId)) {
            planId
        } else {
            "plan1"
        }
        val planPeriods = bellPlansObj.optJSONObject(resolvedPlanId)?.optJSONObject("periods")
            ?: return null
        val itemsArray = scheduleObj.optJSONArray("items") ?: return null

        if (itemsArray.length() == 0) {
            return WidgetStatus(
                subjectName = "ไม่มีข้อมูล",
                timeStr = "-",
                statusBadge = "✨ พักผ่อน",
                nextSubject = "-",
                laterSubject = "",
                dayName = dayName,
                countdownText = "⏱ ตารางเรียน",
                remainingMillis = 0L,
                targetEndMillis = nextMidnightMillis,
                nextTransitionMillis = nextMidnightMillis,
                isBeforeSchool = false,
                isAfterSchool = false,
                isWeekend = false,
                isLiveCountdown = false
            )
        }

        val itemsWithTime = ArrayList<Pair<ScheduleItem, ItemTimeRange>>(itemsArray.length())
        for (i in 0 until itemsArray.length()) {
            val obj = itemsArray.optJSONObject(i) ?: continue
            val item = ScheduleItem(
                type = obj.optNonNullString("type") ?: "subject",
                period = obj.optNonNullString("period"),
                code = obj.optNonNullString("code"),
                name = obj.optNonNullString("name"),
                title = obj.optNonNullString("title")
            )
            itemsWithTime.add(item to getItemTimeRange(item, planPeriods))
        }

        if (itemsWithTime.isEmpty()) return null

        val firstItem = itemsWithTime.first().first
        val firstTime = itemsWithTime.first().second
        val lastTime = itemsWithTime.last().second

        val firstStartMillis = timeAtMinute(midnightCal, firstTime.start)
        val lastEndMillis = timeAtMinute(midnightCal, lastTime.end)

        // 1. Before school
        if (nowMillis < firstStartMillis) {
            val remMillis = (firstStartMillis - nowMillis).coerceAtLeast(0L)
            val remMins = ceil(remMillis / 60_000.0).toInt()
            val nextName = firstItem.name ?: firstItem.title ?: "คาบแรก"
            val nextCode = if (!firstItem.code.isNullOrEmpty() && firstItem.code != "-") {
                " (${firstItem.code})"
            } else {
                ""
            }
            val later = if (itemsWithTime.size > 1) {
                val secondItem = itemsWithTime[1].first
                "ต่อไป: ${secondItem.name ?: secondItem.title ?: ""}"
            } else {
                ""
            }
            return WidgetStatus(
                subjectName = "ยังไม่เริ่มคาบเรียน",
                timeStr = "เริ่ม ${firstTime.timeStr.split(" - ")[0]} น.",
                statusBadge = "⏰ กำลังจะเริ่ม",
                nextSubject = "$nextName$nextCode",
                laterSubject = later,
                dayName = dayName,
                countdownText = "⏱ เริ่มใน $remMins น.",
                remainingMillis = remMillis,
                targetEndMillis = firstStartMillis,
                nextTransitionMillis = firstStartMillis,
                isBeforeSchool = true,
                isAfterSchool = false,
                isWeekend = false,
                isLiveCountdown = remMillis > 0L
            )
        }

        // 2. After school
        if (nowMillis >= lastEndMillis) {
            return WidgetStatus(
                subjectName = "เลิกเรียนแล้ว 🎉",
                timeStr = "หมดคาบเรียนวันนี้",
                statusBadge = "✨ พักผ่อน",
                nextSubject = "พรุ่งนี้เจอกันใหม่นะ!",
                laterSubject = "ดูตารางเรียนวันต่อไปได้",
                dayName = dayName,
                countdownText = "✨ เลิกเรียนแล้ว",
                remainingMillis = 0L,
                targetEndMillis = nextMidnightMillis,
                nextTransitionMillis = nextMidnightMillis,
                isBeforeSchool = false,
                isAfterSchool = true,
                isWeekend = false,
                isLiveCountdown = false
            )
        }

        // 3. During school (period or break)
        for (i in itemsWithTime.indices) {
            val (item, timeInfo) = itemsWithTime[i]
            val startMillis = timeAtMinute(midnightCal, timeInfo.start)
            val endMillis = timeAtMinute(midnightCal, timeInfo.end)

            if (nowMillis in startMillis until endMillis) {
                val remMillis = (endMillis - nowMillis).coerceAtLeast(0L)
                val remMins = ceil(remMillis / 60_000.0).toInt()
                val isBreak = item.type == "break"
                val isLunch = isBreak && (
                    item.title?.contains("กลางวัน") == true ||
                        item.title?.contains("อาหาร") == true
                    )

                val subjectName = if (isBreak) {
                    item.title ?: if (isLunch) "พักกลางวัน" else "พักเบรก"
                } else {
                    item.name ?: item.title ?: "กำลังเรียน"
                }
                val statusBadge = if (isBreak) {
                    if (isLunch) "🍱 พักกลางวัน" else "☕ พักเบรก"
                } else {
                    "🟢 กำลังเรียน"
                }

                val nextSub = if (i + 1 < itemsWithTime.size) {
                    val (nextItem, nextTime) = itemsWithTime[i + 1]
                    val nextTimeStart = nextTime.timeStr.split(" - ")[0]
                    val nextTitle = nextItem.name ?: nextItem.title ?: ""
                    "$nextTitle ($nextTimeStart น.)"
                } else {
                    "คาบสุดท้ายของวันแล้ว 🎉"
                }

                val laterSub = if (i + 2 < itemsWithTime.size) {
                    val (laterItem, laterTime) = itemsWithTime[i + 2]
                    val laterStart = laterTime.timeStr.split(" - ")[0]
                    "ต่อไปอีก: ${laterItem.name ?: laterItem.title ?: ""} ($laterStart น.)"
                } else {
                    ""
                }

                return WidgetStatus(
                    subjectName = subjectName,
                    timeStr = timeInfo.timeStr,
                    statusBadge = statusBadge,
                    nextSubject = nextSub,
                    laterSubject = laterSub,
                    dayName = dayName,
                    countdownText = "⏱ เหลือ $remMins น.",
                    remainingMillis = remMillis,
                    targetEndMillis = endMillis,
                    nextTransitionMillis = endMillis,
                    isBeforeSchool = false,
                    isAfterSchool = false,
                    isWeekend = false,
                    isLiveCountdown = remMillis > 0L
                )
            }
        }

        // 4. Fallback if between gaps
        val nextGapBoundary = itemsWithTime
            .map { timeAtMinute(midnightCal, it.second.start) }
            .firstOrNull { it > nowMillis } ?: nextMidnightMillis

        return WidgetStatus(
            subjectName = "พักผ่อน",
            timeStr = "ระหว่างคาบ",
            statusBadge = "☕ พักเบรก",
            nextSubject = "-",
            laterSubject = "",
            dayName = dayName,
            countdownText = "⏱ พักผ่อน",
            remainingMillis = 0L,
            targetEndMillis = nextGapBoundary,
            nextTransitionMillis = nextGapBoundary,
            isBeforeSchool = false,
            isAfterSchool = false,
            isWeekend = false,
            isLiveCountdown = false
        )
    }

    private fun getItemTimeRange(item: ScheduleItem, planPeriods: JSONObject): ItemTimeRange {
        if (item.type == "break") {
            val title = item.title ?: ""
            return if (title.contains("20") || title.contains("สาย") || title.contains("เช้า")) {
                val b1 = planPeriods.optJSONObject("break1")
                if (b1 != null) {
                    ItemTimeRange(
                        start = b1.optInt("start", 600),
                        end = b1.optInt("end", 620),
                        timeStr = b1.optNonNullString("timeStr") ?: "10.00 - 10.20 น."
                    )
                } else {
                    ItemTimeRange(600, 620, "10.00 - 10.20 น.")
                }
            } else {
                val lunch = planPeriods.optJSONObject("lunch")
                if (lunch != null) {
                    ItemTimeRange(
                        start = lunch.optInt("start", 720),
                        end = lunch.optInt("end", 770),
                        timeStr = lunch.optNonNullString("timeStr") ?: "12.00 - 12.50 น."
                    )
                } else {
                    ItemTimeRange(720, 770, "12.00 - 12.50 น.")
                }
            }
        }

        val range = parsePeriodRange(item.period)
        if (range != null) {
            val p1 = planPeriods.optJSONObject("${range.first}")
            val p2 = planPeriods.optJSONObject("${range.second}")
            if (p1 != null && p2 != null) {
                val p1Time = p1.optNonNullString("timeStr") ?: ""
                val p2Time = p2.optNonNullString("timeStr") ?: ""
                val startTime = p1Time.split(" - ")[0]
                val p2Parts = p2Time.split(" - ")
                val endTime = if (p2Parts.size > 1) p2Parts[1] else p2Time
                return ItemTimeRange(
                    start = p1.optInt("start", 500),
                    end = p2.optInt("end", 550),
                    timeStr = "$startTime - $endTime"
                )
            }
        }

        val p1 = planPeriods.optJSONObject("1")
        return ItemTimeRange(
            start = p1?.optInt("start", 500) ?: 500,
            end = p1?.optInt("end", 550) ?: 550,
            timeStr = p1?.optNonNullString("timeStr") ?: "08.20 - 09.10 น."
        )
    }

    private fun timeAtMinute(midnightCal: Calendar, minuteOfDay: Int): Long {
        return (midnightCal.clone() as Calendar).apply {
            add(Calendar.MINUTE, minuteOfDay)
        }.timeInMillis
    }

    private fun JSONObject.optNonNullString(key: String): String? {
        if (!has(key) || isNull(key)) return null
        return optString(key)
    }
}
