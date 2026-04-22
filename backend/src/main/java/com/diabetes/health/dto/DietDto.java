package com.diabetes.health.dto;

import com.diabetes.health.entity.DailyMealPlan;
import com.diabetes.health.entity.FoodNutrition;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class DietDto {

    @Data
    public static class CreateRecordRequest {
        @NotNull(message = "记录日期不能为空")
        private LocalDate recordDate;
        private Instant recordTime;
        @NotNull(message = "餐次不能为空")
        private String mealType;
        @NotNull(message = "食物不能为空")
        private Long foodId;
        @NotNull(message = "克数不能为空")
        @DecimalMin(value = "0.01", message = "克数必须大于 0")
        private BigDecimal amountG;
        private String remark;
    }

    @Data
    public static class CreateFoodRequest {
        @NotBlank(message = "食物名称不能为空")
        private String name;
        private String category;
        @NotNull(message = "热量不能为空")
        @DecimalMin(value = "0.0", message = "热量不能小于 0")
        private BigDecimal calorieKcalPer100g;
        @NotNull(message = "碳水不能为空")
        @DecimalMin(value = "0.0", message = "碳水不能小于 0")
        private BigDecimal carbGPer100g;
        @NotNull(message = "蛋白质不能为空")
        @DecimalMin(value = "0.0", message = "蛋白质不能小于 0")
        private BigDecimal proteinGPer100g;
        @NotNull(message = "脂肪不能为空")
        @DecimalMin(value = "0.0", message = "脂肪不能小于 0")
        private BigDecimal fatGPer100g;
        @DecimalMin(value = "0.0", message = "GI 不能小于 0")
        private BigDecimal gi;
    }

    @Data
    public static class CreateMealPlanRequest {
        @NotNull(message = "计划日期不能为空")
        private LocalDate planDate;
        @NotBlank(message = "餐次不能为空")
        private String mealType;
        @NotNull(message = "食物不能为空")
        private Long foodId;
        @NotNull(message = "建议克数不能为空")
        @DecimalMin(value = "0.01", message = "建议克数必须大于 0")
        private BigDecimal amountG;
        private String remark;
    }

    @Data
    public static class FoodItemResponse {
        private Long id;
        private Long userId;
        private Boolean customFood;
        private String name;
        private String category;
        private BigDecimal calorieKcalPer100g;
        private BigDecimal carbGPer100g;
        private BigDecimal proteinGPer100g;
        private BigDecimal fatGPer100g;
        private BigDecimal gi;

        public static FoodItemResponse from(FoodNutrition food) {
            if (food == null) {
                return null;
            }
            FoodItemResponse response = new FoodItemResponse();
            response.setId(food.getId());
            response.setUserId(food.getUserId());
            response.setCustomFood(Boolean.TRUE.equals(food.getCustomFood()));
            response.setName(food.getName());
            response.setCategory(food.getCategory());
            response.setCalorieKcalPer100g(food.getCalorieKcalPer100g());
            response.setCarbGPer100g(food.getCarbGPer100g());
            response.setProteinGPer100g(food.getProteinGPer100g());
            response.setFatGPer100g(food.getFatGPer100g());
            response.setGi(food.getGi());
            return response;
        }
    }

    @Data
    public static class RecordResponse {
        private Long id;
        private Long userId;
        private LocalDate recordDate;
        private Instant recordTime;
        private String mealType;
        private Long foodId;
        private String foodName;
        private BigDecimal amountG;
        private BigDecimal calorieKcal;
        private BigDecimal carbG;
        private BigDecimal proteinG;
        private BigDecimal fatG;
        private String remark;
        private Instant createdAt;
    }

    @Data
    public static class DailySummaryResponse {
        private LocalDate date;
        private BigDecimal totalCalorieKcal;
        private BigDecimal totalCarbG;
        private BigDecimal totalProteinG;
        private BigDecimal totalFatG;
        private List<RecordResponse> records;
    }

    @Data
    public static class MealPlanItemResponse {
        private Long id;
        private LocalDate planDate;
        private String mealType;
        private Long foodId;
        private String foodName;
        private String category;
        private BigDecimal amountG;
        private BigDecimal calorieKcal;
        private BigDecimal carbG;
        private BigDecimal proteinG;
        private BigDecimal fatG;
        private String remark;
        private Instant createdAt;

        public static MealPlanItemResponse from(DailyMealPlan plan, FoodNutrition food) {
            if (plan == null) {
                return null;
            }
            MealPlanItemResponse response = new MealPlanItemResponse();
            response.setId(plan.getId());
            response.setPlanDate(plan.getPlanDate());
            response.setMealType(plan.getMealType() != null ? plan.getMealType().name() : null);
            response.setFoodId(plan.getFoodId());
            response.setAmountG(plan.getAmountG());
            response.setRemark(plan.getRemark());
            response.setCreatedAt(plan.getCreatedAt());

            if (food != null) {
                BigDecimal ratio = plan.getAmountG().divide(BigDecimal.valueOf(100), 4, java.math.RoundingMode.HALF_UP);
                response.setFoodName(food.getName());
                response.setCategory(food.getCategory());
                response.setCalorieKcal(scale(food.getCalorieKcalPer100g(), ratio));
                response.setCarbG(scale(food.getCarbGPer100g(), ratio));
                response.setProteinG(scale(food.getProteinGPer100g(), ratio));
                response.setFatG(scale(food.getFatGPer100g(), ratio));
            }
            return response;
        }
    }

    @Data
    public static class DailyMealPlanResponse {
        private LocalDate date;
        private BigDecimal totalCalorieKcal;
        private List<MealPlanItemResponse> items;
    }

    @Data
    public static class DailyRecommendationResponse {
        private LocalDate date;
        private String summary;
        private List<String> tips;
        private List<FoodItemResponse> recommendedFoods;
    }

    @Data
    public static class NutritionAnalysisResponse {
        private LocalDate date;
        private Integer score;
        private String grade;
        private String headline;
        private String summary;
        private BigDecimal totalCalorieKcal;
        private BigDecimal estimatedFiberG;
        private Integer fiberAchievementPct;
        private BigDecimal averageGi;
        private List<MacroBalanceItem> macroBalance;
        private List<MealBalanceItem> mealBalance;
        private List<String> riskFlags;
        private List<String> insights;
        private List<String> actionItems;
        private String nextMealAdvice;
    }

    @Data
    public static class MacroBalanceItem {
        private String key;
        private String label;
        private BigDecimal grams;
        private BigDecimal calorieSharePct;
        private BigDecimal targetMinPct;
        private BigDecimal targetMaxPct;
        private String status;
    }

    @Data
    public static class MealBalanceItem {
        private String mealType;
        private String mealLabel;
        private BigDecimal calorieKcal;
        private BigDecimal carbG;
        private BigDecimal proteinG;
        private BigDecimal fatG;
        private Integer recordCount;
        private String status;
    }

    @Data
    public static class PageResult<T> {
        private List<T> content;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;
    }

    private static BigDecimal scale(BigDecimal value, BigDecimal ratio) {
        if (value == null) {
            return null;
        }
        return value.multiply(ratio).setScale(2, java.math.RoundingMode.HALF_UP);
    }
}
