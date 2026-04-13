package com.diabetes.health.service;

import com.diabetes.health.dto.BloodGlucoseDto;
import com.diabetes.health.dto.DashboardDto;
import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.ExerciseRecord;
import com.diabetes.health.repository.BloodGlucoseRecordRepository;
import com.diabetes.health.repository.DietRecordRepository;
import com.diabetes.health.repository.ExerciseRecordRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final BloodGlucoseRecordRepository bloodGlucoseRecordRepository;
    private final DietRecordRepository dietRecordRepository;
    private final ExerciseRecordRepository exerciseRecordRepository;

    public DashboardDto.TodayResponse today(CurrentUser user) {
        ZoneId zone = ZoneId.systemDefault();
        LocalDate today = LocalDate.now(zone);
        Instant start = today.atStartOfDay(zone).toInstant();
        Instant end = today.plusDays(1).atStartOfDay(zone).toInstant();

        List<BloodGlucoseRecord> glucoseRecords = bloodGlucoseRecordRepository.findByUserIdAndMeasureTimeBetween(user.getId(), start, end);
        List<DietRecord> dietRecords = dietRecordRepository.findByUserIdAndRecordDateOrderByRecordTimeDesc(user.getId(), today);
        List<ExerciseRecord> exerciseRecords = exerciseRecordRepository.findByUserIdAndStartTimeBetweenOrderByStartTimeDesc(user.getId(), start, end);

        DashboardDto.TodayResponse response = new DashboardDto.TodayResponse();
        response.setLatestGlucose(glucoseRecords.stream()
                .max(Comparator.comparing(BloodGlucoseRecord::getMeasureTime))
                .map(BloodGlucoseDto.RecordResponse::from)
                .orElse(null));
        response.setTodayTotalCalorieEaten(sum(dietRecords.stream().map(DietRecord::getCalorieKcal).toList()));
        response.setTodayTotalCalorieBurned(sum(exerciseRecords.stream().map(ExerciseRecord::getCalorieKcal).toList()));

        List<String> reminders = new ArrayList<>();
        if (glucoseRecords.isEmpty()) {
            reminders.add("记得记录今天的血糖");
        }
        if (dietRecords.isEmpty()) {
            reminders.add("可以先添加一份今日食谱，安排更省心");
        }
        if (response.getTodayTotalCalorieEaten().compareTo(new BigDecimal("1600")) > 0) {
            reminders.add("今日热量偏高，晚餐建议清淡并增加步行");
        } else {
            reminders.add("今天适合继续保持低 GI 主食与优质蛋白搭配");
        }
        response.setReminders(reminders);
        return response;
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
