package com.diabetes.health.service;

import com.diabetes.health.entity.*;
import com.diabetes.health.repository.*;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {

    @Mock private BloodGlucoseRecordRepository bloodGlucoseRecordRepository;
    @Mock private DietRecordRepository dietRecordRepository;
    @Mock private ExerciseRecordRepository exerciseRecordRepository;
    @Mock private HealthReminderRepository healthReminderRepository;
    @InjectMocks private DashboardService dashboardService;

    private CurrentUser currentUser() {
        return new CurrentUser(1L, "13800138000", "PATIENT");
    }

    @Test
    void today_withGlucoseRecord_returnsLatest() {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Shanghai"));
        Instant start = today.atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();

        BloodGlucoseRecord record = BloodGlucoseRecord.builder()
                .id(1L).userId(1L).measureType(BloodGlucoseRecord.MeasureType.FASTING)
                .valueMmolL(new BigDecimal("5.6")).measureTime(Instant.now()).build();

        when(bloodGlucoseRecordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(1L, start, end))
                .thenReturn(List.of(record));
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, today))
                .thenReturn(List.of());
        when(exerciseRecordRepository.findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(healthReminderRepository.findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(1L))
                .thenReturn(List.of());

        var result = dashboardService.today(currentUser());
        assertThat(result.getLatestGlucose()).isNotNull();
        assertThat(result.getLatestGlucose().getValueMmolL()).isEqualByComparingTo("5.6");
    }

    @Test
    void today_noGlucoseRecord_returnsNull() {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Shanghai"));
        Instant start = today.atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();

        when(bloodGlucoseRecordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, today))
                .thenReturn(List.of());
        when(exerciseRecordRepository.findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(healthReminderRepository.findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(1L))
                .thenReturn(List.of());

        var result = dashboardService.today(currentUser());
        assertThat(result.getLatestGlucose()).isNull();
    }

    @Test
    void today_withDietRecords_sumsCalories() {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Shanghai"));
        Instant start = today.atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();

        DietRecord d1 = DietRecord.builder().calorieKcal(new BigDecimal("300.00")).build();
        DietRecord d2 = DietRecord.builder().calorieKcal(new BigDecimal("450.00")).build();

        when(bloodGlucoseRecordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, today))
                .thenReturn(List.of(d1, d2));
        when(exerciseRecordRepository.findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(healthReminderRepository.findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(1L))
                .thenReturn(List.of());

        var result = dashboardService.today(currentUser());
        assertThat(result.getTodayTotalCalorieEaten()).isEqualByComparingTo("750.00");
    }

    @Test
    void today_withReminders_buildsTexts() {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Shanghai"));
        Instant start = today.atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();

        HealthReminder reminder = HealthReminder.builder()
                .type(HealthReminder.ReminderType.GLUCOSE_TEST)
                .timeOfDay(LocalTime.of(8, 0))
                .remark("空腹测血糖").build();

        when(bloodGlucoseRecordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, today))
                .thenReturn(List.of());
        when(exerciseRecordRepository.findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(healthReminderRepository.findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(1L))
                .thenReturn(List.of(reminder));

        var result = dashboardService.today(currentUser());
        assertThat(result.getReminders()).hasSize(1);
        assertThat(result.getReminders().get(0)).contains("血糖提醒");
    }

    @Test
    void today_noReminders_showsFallback() {
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Shanghai"));
        Instant start = today.atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();

        when(bloodGlucoseRecordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, today))
                .thenReturn(List.of());
        when(exerciseRecordRepository.findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(1L, start, end))
                .thenReturn(List.of());
        when(healthReminderRepository.findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(1L))
                .thenReturn(List.of());

        var result = dashboardService.today(currentUser());
        assertThat(result.getReminders()).hasSize(1);
        assertThat(result.getReminders().get(0)).contains("没有启用提醒");
    }
}
