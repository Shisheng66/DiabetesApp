package com.diabetes.health.service;

import com.diabetes.health.dto.BloodGlucoseDto;
import com.diabetes.health.dto.DashboardDto;
import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.ExerciseRecord;
import com.diabetes.health.entity.HealthReminder;
import com.diabetes.health.repository.BloodGlucoseRecordRepository;
import com.diabetes.health.repository.DietRecordRepository;
import com.diabetes.health.repository.ExerciseRecordRepository;
import com.diabetes.health.repository.HealthReminderRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private static final ZoneId APP_ZONE = ZoneId.of("Asia/Shanghai");

    private final BloodGlucoseRecordRepository bloodGlucoseRecordRepository;
    private final DietRecordRepository dietRecordRepository;
    private final ExerciseRecordRepository exerciseRecordRepository;
    private final HealthReminderRepository healthReminderRepository;

    @Cacheable(value = "dashboard", key = "#user.id", unless = "#result == null")
    public DashboardDto.TodayResponse today(CurrentUser user) {
        LocalDate today = LocalDate.now(APP_ZONE);
        Instant start = today.atStartOfDay(APP_ZONE).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(APP_ZONE).toInstant();

        List<BloodGlucoseRecord> glucoseRecords = bloodGlucoseRecordRepository
                .findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(user.getId(), start, end);
        List<DietRecord> dietRecords = dietRecordRepository.findByUserIdAndRecordDateOrderByRecordTimeDesc(user.getId(), today);
        List<ExerciseRecord> exerciseRecords = exerciseRecordRepository.findByUserIdAndStartTimeBetweenOrderByStartTimeDesc(user.getId(), start, end);
        List<HealthReminder> remindersFromDb = healthReminderRepository.findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(user.getId());

        DashboardDto.TodayResponse response = new DashboardDto.TodayResponse();
        response.setLatestGlucose(glucoseRecords.isEmpty()
                ? null
                : BloodGlucoseDto.RecordResponse.from(glucoseRecords.get(0)));
        response.setTodayTotalCalorieEaten(sum(dietRecords.stream().map(DietRecord::getCalorieKcal).toList()));
        response.setTodayTotalCalorieBurned(sum(exerciseRecords.stream().map(ExerciseRecord::getCalorieKcal).toList()));
        response.setReminders(buildReminderTexts(remindersFromDb));
        return response;
    }

    private List<String> buildReminderTexts(List<HealthReminder> reminders) {
        List<String> texts = new ArrayList<>();
        for (HealthReminder reminder : reminders) {
            String time = reminder.getTimeOfDay() == null ? "--:--" : reminder.getTimeOfDay().toString();
            String type = switch (reminder.getType()) {
                case GLUCOSE_TEST -> "血糖提醒";
                case MEDICINE -> "用药提醒";
                case EXERCISE -> "运动提醒";
                case DIET -> "饮食提醒";
            };
            String remark = reminder.getRemark() == null || reminder.getRemark().isBlank()
                    ? ""
                    : " · " + reminder.getRemark();
            texts.add(type + " " + time + remark);
        }
        if (texts.isEmpty()) {
            texts.add("当前没有启用提醒，请在“我的”页面中配置提醒。");
        }
        return texts;
    }

    private BigDecimal sum(List<BigDecimal> values) {
        BigDecimal result = BigDecimal.ZERO;
        for (BigDecimal value : values) {
            if (value != null) {
                result = result.add(value);
            }
        }
        return result.setScale(2, RoundingMode.HALF_UP);
    }
}
