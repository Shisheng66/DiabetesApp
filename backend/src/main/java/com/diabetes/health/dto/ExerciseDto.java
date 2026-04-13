package com.diabetes.health.dto;

import com.diabetes.health.entity.ExerciseType;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class ExerciseDto {

    @Data
    public static class CreateRecordRequest {
        @NotNull(message = "运动类型不能为空")
        private Long exerciseTypeId;

        @NotNull(message = "开始时间不能为空")
        private Instant startTime;

        private Instant endTime;
        private Integer durationMin;
        private BigDecimal distanceKm;
        private BigDecimal calorieKcal;
        private String remark;
    }

    @Data
    public static class TypeResponse {
        private Long id;
        private String code;
        private String name;
        private BigDecimal metValue;

        public static TypeResponse from(ExerciseType type) {
            if (type == null) {
                return null;
            }
            TypeResponse response = new TypeResponse();
            response.setId(type.getId());
            response.setCode(type.getCode());
            response.setName(type.getName());
            response.setMetValue(type.getMetValue());
            return response;
        }
    }

    @Data
    public static class RecordResponse {
        private Long id;
        private Long userId;
        private Long exerciseTypeId;
        private String exerciseTypeName;
        private Instant startTime;
        private Instant endTime;
        private Integer durationMin;
        private BigDecimal distanceKm;
        private BigDecimal calorieKcal;
        private String remark;
        private Instant createdAt;
    }

    @Data
    public static class DailySummaryResponse {
        private String date;
        private Integer totalDurationMin;
        private BigDecimal totalCalorieKcal;
        private List<RecordResponse> records;
    }

    @Data
    public static class SuggestionItem {
        private Long exerciseTypeId;
        private String exerciseTypeName;
        private BigDecimal estimatedCalorieKcal;
        private Integer recommendedMinutes;
    }

    @Data
    public static class DailyRecommendationResponse {
        private LocalDate date;
        private BigDecimal todayCalorieIntake;
        private BigDecimal todayCalorieBurned;
        private BigDecimal suggestedBurnKcal;
        private BigDecimal remainingBurnKcal;
        private List<SuggestionItem> suggestions;
        private String summary;
    }
}
