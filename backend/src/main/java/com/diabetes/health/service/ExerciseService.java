package com.diabetes.health.service;

import com.diabetes.health.dto.ExerciseDto;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.ExerciseRecord;
import com.diabetes.health.entity.ExerciseType;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.DietRecordRepository;
import com.diabetes.health.repository.ExerciseRecordRepository;
import com.diabetes.health.repository.ExerciseTypeRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ExerciseService {

    private final ExerciseRecordRepository exerciseRecordRepository;
    private final ExerciseTypeRepository exerciseTypeRepository;
    private final DietRecordRepository dietRecordRepository;
    private final UserHealthProfileRepository userHealthProfileRepository;

    @Transactional
    public ExerciseDto.RecordResponse create(CurrentUser user, ExerciseDto.CreateRecordRequest req) {
        ExerciseType type = exerciseTypeRepository.findById(req.getExerciseTypeId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "运动类型不存在"));

        Integer durationMin = req.getDurationMin();
        if (durationMin == null && req.getStartTime() != null && req.getEndTime() != null) {
            durationMin = (int) ((req.getEndTime().getEpochSecond() - req.getStartTime().getEpochSecond()) / 60);
        }

        BigDecimal calorieKcal = req.getCalorieKcal();
        if (calorieKcal == null && durationMin != null && type.getMetValue() != null) {
            BigDecimal weight = resolveUserWeight(user.getId());
            double hours = durationMin / 60.0;
            calorieKcal = type.getMetValue()
                    .multiply(weight)
                    .multiply(BigDecimal.valueOf(hours))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        ExerciseRecord record = ExerciseRecord.builder()
                .userId(user.getId())
                .exerciseTypeId(type.getId())
                .startTime(req.getStartTime())
                .endTime(req.getEndTime())
                .durationMin(durationMin)
                .distanceKm(req.getDistanceKm())
                .calorieKcal(calorieKcal)
                .remark(req.getRemark())
                .build();
        return toRecordResponse(exerciseRecordRepository.save(record), type.getName());
    }

    public List<ExerciseDto.RecordResponse> list(CurrentUser user, LocalDate startDate, LocalDate endDate, int page, int size) {
        if (startDate != null && endDate != null) {
            ZoneId zone = ZoneId.systemDefault();
            Instant start = startDate.atStartOfDay(zone).toInstant();
            Instant end = endDate.plusDays(1).atStartOfDay(zone).toInstant();
            List<ExerciseRecord> list = exerciseRecordRepository.findByUserIdAndStartTimeBetweenOrderByStartTimeDesc(user.getId(), start, end);
            return list.stream()
                    .map(record -> toRecordResponse(record, resolveExerciseName(record.getExerciseTypeId())))
                    .toList();
        }

        List<ExerciseRecord> list = exerciseRecordRepository.findByUserIdOrderByStartTimeDesc(user.getId(), PageRequest.of(page, size));
        return list.stream()
                .map(record -> toRecordResponse(record, resolveExerciseName(record.getExerciseTypeId())))
                .toList();
    }

    public ExerciseDto.DailySummaryResponse getDailySummary(CurrentUser user, LocalDate date) {
        ZoneId zone = ZoneId.systemDefault();
        Instant start = date.atStartOfDay(zone).toInstant();
        Instant end = date.plusDays(1).atStartOfDay(zone).toInstant();
        List<ExerciseRecord> list = exerciseRecordRepository.findByUserIdAndStartTimeBetweenOrderByStartTimeDesc(user.getId(), start, end);

        ExerciseDto.DailySummaryResponse response = new ExerciseDto.DailySummaryResponse();
        response.setDate(date.toString());
        response.setTotalDurationMin(list.stream()
                .filter(record -> record.getDurationMin() != null)
                .mapToInt(ExerciseRecord::getDurationMin)
                .sum());
        response.setTotalCalorieKcal(sum(list.stream().map(ExerciseRecord::getCalorieKcal).toList()));
        response.setRecords(list.stream()
                .map(record -> toRecordResponse(record, resolveExerciseName(record.getExerciseTypeId())))
                .toList());
        return response;
    }

    public void delete(CurrentUser user, Long id) {
        ExerciseRecord record = exerciseRecordRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "运动记录不存在"));
        if (!record.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权删除该记录");
        }
        exerciseRecordRepository.delete(record);
    }

    public List<ExerciseDto.TypeResponse> listExerciseTypes() {
        return exerciseTypeRepository.findAll().stream().map(ExerciseDto.TypeResponse::from).toList();
    }

    public ExerciseDto.DailyRecommendationResponse getDailyRecommendation(CurrentUser user, LocalDate date) {
        BigDecimal intake = sum(dietRecordRepository.findByUserIdAndRecordDateOrderByRecordTimeDesc(user.getId(), date)
                .stream()
                .map(DietRecord::getCalorieKcal)
                .toList());

        ZoneId zone = ZoneId.systemDefault();
        Instant start = date.atStartOfDay(zone).toInstant();
        Instant end = date.plusDays(1).atStartOfDay(zone).toInstant();
        BigDecimal burned = sum(exerciseRecordRepository.findByUserIdAndStartTimeBetweenOrderByStartTimeDesc(user.getId(), start, end)
                .stream()
                .map(ExerciseRecord::getCalorieKcal)
                .toList());

        BigDecimal weight = resolveUserWeight(user.getId());
        BigDecimal recommendedIntake = weight.multiply(new BigDecimal("25"));
        BigDecimal suggestedBurn = intake.compareTo(recommendedIntake) > 0
                ? intake.subtract(recommendedIntake).multiply(new BigDecimal("0.45")).add(new BigDecimal("120"))
                : intake.multiply(new BigDecimal("0.12")).max(new BigDecimal("90"));
        suggestedBurn = suggestedBurn.min(new BigDecimal("600")).setScale(2, RoundingMode.HALF_UP);
        BigDecimal remaining = suggestedBurn.subtract(burned).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);

        List<ExerciseDto.SuggestionItem> suggestions = exerciseTypeRepository.findAll().stream()
                .filter(type -> type.getMetValue() != null)
                .map(type -> toSuggestion(type, weight, remaining))
                .sorted((a, b) -> Integer.compare(a.getRecommendedMinutes(), b.getRecommendedMinutes()))
                .limit(4)
                .toList();

        ExerciseDto.DailyRecommendationResponse response = new ExerciseDto.DailyRecommendationResponse();
        response.setDate(date);
        response.setTodayCalorieIntake(intake);
        response.setTodayCalorieBurned(burned);
        response.setSuggestedBurnKcal(suggestedBurn);
        response.setRemainingBurnKcal(remaining);
        response.setSuggestions(suggestions);
        if (remaining.compareTo(BigDecimal.ZERO) <= 0) {
            response.setSummary("今天的运动消耗已经达到建议目标，保持补水和拉伸即可。");
        } else {
            response.setSummary("根据你今天的饮食摄入，建议再消耗约 " + remaining.toPlainString() + " kcal，下面这些运动更合适。");
        }
        return response;
    }

    private ExerciseDto.SuggestionItem toSuggestion(ExerciseType type, BigDecimal weight, BigDecimal remaining) {
        BigDecimal caloriePerHour = type.getMetValue().multiply(weight);
        BigDecimal caloriePerMinute = caloriePerHour.divide(new BigDecimal("60"), 4, RoundingMode.HALF_UP);
        int recommendedMinutes = remaining.compareTo(BigDecimal.ZERO) <= 0
                ? 10
                : remaining.divide(caloriePerMinute, 0, RoundingMode.UP).intValue();
        recommendedMinutes = Math.max(10, recommendedMinutes);

        ExerciseDto.SuggestionItem item = new ExerciseDto.SuggestionItem();
        item.setExerciseTypeId(type.getId());
        item.setExerciseTypeName(type.getName());
        item.setRecommendedMinutes(recommendedMinutes);
        item.setEstimatedCalorieKcal(caloriePerMinute
                .multiply(BigDecimal.valueOf(recommendedMinutes))
                .setScale(2, RoundingMode.HALF_UP));
        return item;
    }

    private BigDecimal resolveUserWeight(Long userId) {
        return userHealthProfileRepository.findByUserId(userId)
                .map(UserHealthProfile::getWeightKg)
                .filter(weight -> weight != null && weight.compareTo(BigDecimal.ZERO) > 0)
                .orElse(new BigDecimal("65"));
    }

    private String resolveExerciseName(Long exerciseTypeId) {
        return exerciseTypeRepository.findById(exerciseTypeId)
                .map(ExerciseType::getName)
                .orElse("运动");
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

    private ExerciseDto.RecordResponse toRecordResponse(ExerciseRecord record, String typeName) {
        ExerciseDto.RecordResponse response = new ExerciseDto.RecordResponse();
        response.setId(record.getId());
        response.setUserId(record.getUserId());
        response.setExerciseTypeId(record.getExerciseTypeId());
        response.setExerciseTypeName(typeName);
        response.setStartTime(record.getStartTime());
        response.setEndTime(record.getEndTime());
        response.setDurationMin(record.getDurationMin());
        response.setDistanceKm(record.getDistanceKm());
        response.setCalorieKcal(record.getCalorieKcal());
        response.setRemark(record.getRemark());
        response.setCreatedAt(record.getCreatedAt());
        return response;
    }
}

