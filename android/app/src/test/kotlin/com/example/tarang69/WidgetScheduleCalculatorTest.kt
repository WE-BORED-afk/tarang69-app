package com.example.tarang69

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.util.Calendar
import java.util.TimeZone

class WidgetScheduleCalculatorTest {
    private val bkkZone: TimeZone = TimeZone.getTimeZone("Asia/Bangkok")

    private fun loadRealScheduleJson(): String {
        val candidates = listOf(
            File("../../assets/data/schedule.json"),
            File("assets/data/schedule.json"),
            File("../assets/data/schedule.json")
        )
        return candidates.first { it.exists() }.readText(Charsets.UTF_8)
    }

    private fun at(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int = 0): Long {
        val cal = Calendar.getInstance(bkkZone)
        cal.set(Calendar.YEAR, year)
        cal.set(Calendar.MONTH, month - 1)
        cal.set(Calendar.DAY_OF_MONTH, day)
        cal.set(Calendar.HOUR_OF_DAY, hour)
        cal.set(Calendar.MINUTE, minute)
        cal.set(Calendar.SECOND, second)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    @Test
    fun parsePeriodRange_handlesSingleDoubleTripleAndInvalid() {
        assertEquals(Pair(1, 1), WidgetScheduleCalculator.parsePeriodRange("คาบที่ 1 (08.20 - 09.10 น.)"))
        assertEquals(Pair(3, 4), WidgetScheduleCalculator.parsePeriodRange("คาบที่ 3 - 4 (10.20 - 12.00 น.)"))
        assertEquals(Pair(6, 8), WidgetScheduleCalculator.parsePeriodRange("คาบที่ 6 - 8 (13.40 - 16.10 น.)"))
        assertNull(WidgetScheduleCalculator.parsePeriodRange(null))
        assertNull(WidgetScheduleCalculator.parsePeriodRange("กิจกรรม"))
    }

    @Test
    fun beforeSchoolOnMonday_returnsUpcomingPeriodAndExactStartTransition() {
        val json = loadRealScheduleJson()
        val now = at(2026, 11, 9, 8, 0, 0) // Monday 08:00
        val status = WidgetScheduleCalculator.calculate(json, "plan1", now, bkkZone)!!

        assertTrue(status.isBeforeSchool)
        assertTrue(status.isLiveCountdown)
        assertEquals("ยังไม่เริ่มคาบเรียน", status.subjectName)
        assertEquals("เริ่ม 08.20 น.", status.timeStr)
        assertEquals("⏰ กำลังจะเริ่ม", status.statusBadge)
        assertEquals("ชีวะ (ว33103)", status.nextSubject)
        assertEquals("ต่อไป: ภาษาอังกฤษอ่าน-เขียน", status.laterSubject)
        assertEquals("วันจันทร์", status.dayName)
        assertEquals("⏱ เริ่มใน 20 น.", status.countdownText)
        assertEquals(20 * 60_000L, status.remainingMillis)
        assertEquals(at(2026, 11, 9, 8, 20), status.targetEndMillis)
        assertEquals(at(2026, 11, 9, 8, 20), status.nextTransitionMillis)
    }

    @Test
    fun morningBreakOnMonday_returnsBreakStatusAndDoublePeriodNext() {
        val json = loadRealScheduleJson()
        val now = at(2026, 11, 9, 10, 5, 0) // Monday 10:05
        val status = WidgetScheduleCalculator.calculate(json, "plan1", now, bkkZone)!!

        assertFalse(status.isBeforeSchool)
        assertTrue(status.isLiveCountdown)
        assertEquals("☕ พักเบรก", status.statusBadge)
        assertEquals("วิชาคอมพิวเตอร์ (10.20 น.)", status.nextSubject)
        assertEquals("⏱ เหลือ 15 น.", status.countdownText)
        assertEquals(15 * 60_000L, status.remainingMillis)
        assertEquals(at(2026, 11, 9, 10, 20), status.nextTransitionMillis)
    }

    @Test
    fun doublePeriodOnMonday_combinesTimeRangeAndRemainingMillis() {
        val json = loadRealScheduleJson()
        val now = at(2026, 11, 9, 11, 0, 0) // Monday 11:00
        val status = WidgetScheduleCalculator.calculate(json, "plan1", now, bkkZone)!!

        assertEquals("วิชาคอมพิวเตอร์", status.subjectName)
        assertEquals("10.20 - 12.00 น.", status.timeStr)
        assertEquals("🟢 กำลังเรียน", status.statusBadge)
        assertEquals("พักกลางวัน 50 นาที (12.00 น.)", status.nextSubject)
        assertEquals("⏱ เหลือ 60 น.", status.countdownText)
        assertEquals(60 * 60_000L, status.remainingMillis)
        assertEquals(at(2026, 11, 9, 12, 0), status.nextTransitionMillis)
    }

    @Test
    fun lunchBreakOnMonday_returnsLunchStatus() {
        val json = loadRealScheduleJson()
        val now = at(2026, 11, 9, 12, 15, 0) // Monday 12:15
        val status = WidgetScheduleCalculator.calculate(json, "plan1", now, bkkZone)!!

        assertEquals("🍱 พักกลางวัน", status.statusBadge)
        assertEquals("คณิตศาสตร์พื้นฐาน (12.50 น.)", status.nextSubject)
        assertEquals(35 * 60_000L, status.remainingMillis)
        assertEquals(at(2026, 11, 9, 12, 50), status.nextTransitionMillis)
    }

    @Test
    fun afterSchoolOnFriday_transitionsAtMidnightToSaturday() {
        val json = loadRealScheduleJson()
        val now = at(2026, 11, 13, 16, 10, 0) // Friday 16:10
        val status = WidgetScheduleCalculator.calculate(json, "plan1", now, bkkZone)!!

        assertFalse(status.isLiveCountdown)
        assertEquals("เลิกเรียนแล้ว 🎉", status.subjectName)
        assertEquals("✨ เลิกเรียนแล้ว", status.countdownText)
        assertEquals(0L, status.remainingMillis)
        assertEquals(at(2026, 11, 14, 0, 0), status.nextTransitionMillis)
    }

    @Test
    fun weekend_transitionsAtMidnightAndShowsHoliday() {
        val json = loadRealScheduleJson()
        val satStatus = WidgetScheduleCalculator.calculate(json, "plan1", at(2026, 11, 14, 10, 30), bkkZone)!!
        val sunStatus = WidgetScheduleCalculator.calculate(json, "plan1", at(2026, 11, 15, 10, 30), bkkZone)!!

        assertFalse(satStatus.isLiveCountdown)
        assertTrue(satStatus.subjectName.contains("วันเสาร์"))
        assertEquals("🎉 วันหยุด", satStatus.statusBadge)
        assertEquals("🎉 วันหยุด", satStatus.countdownText)
        assertEquals(at(2026, 11, 15, 0, 0), satStatus.nextTransitionMillis)

        assertTrue(sunStatus.subjectName.contains("วันอาทิตย์"))
        assertEquals(at(2026, 11, 16, 0, 0), sunStatus.nextTransitionMillis)
    }

    @Test
    fun plan4ExtendedLunch_keepsLunchAt1230() {
        val json = loadRealScheduleJson()
        val status = WidgetScheduleCalculator.calculate(json, "plan4", at(2026, 11, 9, 12, 30), bkkZone)!!

        assertEquals("🍱 พักกลางวัน", status.statusBadge)
        assertEquals("11.20 - 13.10 น.", status.timeStr)
        assertEquals(40 * 60_000L, status.remainingMillis)
        assertEquals(at(2026, 11, 9, 13, 10), status.nextTransitionMillis)
    }

    @Test
    fun invalidOrBlankJson_returnsNullSafely() {
        assertNull(WidgetScheduleCalculator.calculate(null, "plan1", 0L, bkkZone))
        assertNull(WidgetScheduleCalculator.calculate("{bad-json", "plan1", 0L, bkkZone))
    }
}
