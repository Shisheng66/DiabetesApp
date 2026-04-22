package com.diabetes.health.service;

import com.diabetes.health.dto.DietDto;
import com.diabetes.health.entity.DailyMealPlan;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.FoodNutrition;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.DailyMealPlanRepository;
import com.diabetes.health.repository.DietRecordRepository;
import com.diabetes.health.repository.FoodNutritionRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DietService {

    private final DietRecordRepository dietRecordRepository;
    private final FoodNutritionRepository foodNutritionRepository;
    private final DailyMealPlanRepository dailyMealPlanRepository;
    private final UserHealthProfileRepository userHealthProfileRepository;

    @Transactional
    @CacheEvict(value = "dashboard", key = "#user.id")
    public DietDto.RecordResponse create(CurrentUser user, DietDto.CreateRecordRequest req) {
        FoodNutrition food = findAccessibleFood(user.getId(), req.getFoodId());
        DietRecord.MealType mealType = parseMealType(req.getMealType());
        BigDecimal ratio = req.getAmountG().divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);

        Instant recordTime = req.getRecordTime() != null ? req.getRecordTime() : Instant.now();
        DietRecord record = DietRecord.builder()
                .userId(user.getId())
                .recordDate(req.getRecordDate())
                .recordTime(recordTime)
                .mealType(mealType)
                .foodId(food.getId())
                .amountG(req.getAmountG())
                .calorieKcal(scale(food.getCalorieKcalPer100g(), ratio))
                .carbG(scale(food.getCarbGPer100g(), ratio))
                .proteinG(scale(food.getProteinGPer100g(), ratio))
                .fatG(scale(food.getFatGPer100g(), ratio))
                .remark(req.getRemark())
                .build();
        return toRecordResponse(dietRecordRepository.save(record), food.getName());
    }

    @Transactional
    public DietDto.FoodItemResponse createFood(CurrentUser user, DietDto.CreateFoodRequest req) {
        FoodNutrition food = FoodNutrition.builder()
                .userId(user.getId())
                .customFood(true)
                .name(req.getName().trim())
                .category(req.getCategory())
                .calorieKcalPer100g(req.getCalorieKcalPer100g())
                .carbGPer100g(req.getCarbGPer100g())
                .proteinGPer100g(req.getProteinGPer100g())
                .fatGPer100g(req.getFatGPer100g())
                .gi(req.getGi())
                .build();
        return DietDto.FoodItemResponse.from(foodNutritionRepository.save(food));
    }

    public List<DietDto.RecordResponse> listByDate(CurrentUser user, LocalDate date, String mealType) {
        List<DietRecord> list;
        if (mealType != null && !mealType.isBlank()) {
            list = dietRecordRepository.findByUserIdAndRecordDateAndMealTypeOrderByRecordTimeDesc(
                    user.getId(), date, parseMealType(mealType));
        } else {
            list = dietRecordRepository.findByUserIdAndRecordDateOrderByRecordTimeDesc(user.getId(), date);
        }

        Map<Long, FoodNutrition> foods = loadFoods(list.stream().map(DietRecord::getFoodId).toList());
        return list.stream()
                .map(record -> toRecordResponse(record, foods.get(record.getFoodId()) != null
                        ? foods.get(record.getFoodId()).getName() : ""))
                .toList();
    }

    public DietDto.DailySummaryResponse getDailySummary(CurrentUser user, LocalDate date) {
        List<DietRecord> list = dietRecordRepository.findByUserIdAndRecordDateOrderByRecordTimeDesc(user.getId(), date);
        Map<Long, FoodNutrition> foods = loadFoods(list.stream().map(DietRecord::getFoodId).toList());

        BigDecimal totalCal = sum(list.stream().map(DietRecord::getCalorieKcal).toList());
        BigDecimal totalCarb = sum(list.stream().map(DietRecord::getCarbG).toList());
        BigDecimal totalProtein = sum(list.stream().map(DietRecord::getProteinG).toList());
        BigDecimal totalFat = sum(list.stream().map(DietRecord::getFatG).toList());

        DietDto.DailySummaryResponse response = new DietDto.DailySummaryResponse();
        response.setDate(date);
        response.setTotalCalorieKcal(totalCal);
        response.setTotalCarbG(totalCarb);
        response.setTotalProteinG(totalProtein);
        response.setTotalFatG(totalFat);
        response.setRecords(list.stream()
                .map(record -> toRecordResponse(record, foods.get(record.getFoodId()) != null
                        ? foods.get(record.getFoodId()).getName() : ""))
                .toList());
        return response;
    }

    @Transactional
    @CacheEvict(value = "dashboard", key = "#user.id")
    public void delete(CurrentUser user, Long id) {
        DietRecord record = dietRecordRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "饮食记录不存在"));
        if (!record.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权删除该记录");
        }
        dietRecordRepository.delete(record);
    }

    public DietDto.PageResult<DietDto.FoodItemResponse> searchFoods(CurrentUser user, String keyword, int page, int size) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        int safeSize = Math.max(size, 1);
        int safePage = Math.max(page, 0);
        Page<FoodNutrition> foodPage = foodNutritionRepository.searchAccessibleFoods(
                user.getId(),
                normalizedKeyword,
                PageRequest.of(safePage, safeSize)
        );

        List<DietDto.FoodItemResponse> content = foodPage.getContent().stream()
                .map(DietDto.FoodItemResponse::from)
                .toList();

        DietDto.PageResult<DietDto.FoodItemResponse> result = new DietDto.PageResult<>();
        result.setContent(content);
        result.setPage(foodPage.getNumber());
        result.setSize(safeSize);
        result.setTotalElements(foodPage.getTotalElements());
        result.setTotalPages(foodPage.getTotalPages());
        return result;
    }

    @Transactional
    public DietDto.MealPlanItemResponse createMealPlan(CurrentUser user, DietDto.CreateMealPlanRequest request) {
        FoodNutrition food = findAccessibleFood(user.getId(), request.getFoodId());
        DailyMealPlan plan = DailyMealPlan.builder()
                .userId(user.getId())
                .planDate(request.getPlanDate())
                .mealType(parseMealType(request.getMealType()))
                .foodId(food.getId())
                .amountG(request.getAmountG())
                .remark(request.getRemark())
                .build();
        return DietDto.MealPlanItemResponse.from(dailyMealPlanRepository.save(plan), food);
    }

    public DietDto.DailyMealPlanResponse getDailyMealPlan(CurrentUser user, LocalDate date) {
        List<DailyMealPlan> plans = dailyMealPlanRepository.findByUserIdAndPlanDateOrderByMealTypeAscCreatedAtAsc(user.getId(), date);
        Map<Long, FoodNutrition> foods = loadFoods(plans.stream().map(DailyMealPlan::getFoodId).toList());

        List<DietDto.MealPlanItemResponse> items = plans.stream()
                .map(plan -> DietDto.MealPlanItemResponse.from(plan, foods.get(plan.getFoodId())))
                .toList();

        BigDecimal totalCalorie = sum(items.stream().map(DietDto.MealPlanItemResponse::getCalorieKcal).toList());

        DietDto.DailyMealPlanResponse response = new DietDto.DailyMealPlanResponse();
        response.setDate(date);
        response.setTotalCalorieKcal(totalCalorie);
        response.setItems(items);
        return response;
    }

    public void deleteMealPlan(CurrentUser user, Long id) {
        DailyMealPlan plan = dailyMealPlanRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "食谱计划不存在"));
        if (!plan.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权删除该食谱计划");
        }
        dailyMealPlanRepository.delete(plan);
    }

    public DietDto.DailyRecommendationResponse getDailyRecommendation(CurrentUser user, LocalDate date) {
        DietDto.DailySummaryResponse summary = getDailySummary(user, date);
        UserHealthProfile profile = userHealthProfileRepository.findByUserId(user.getId()).orElse(null);

        List<FoodNutrition> candidateFoods = new ArrayList<>(
                foodNutritionRepository.searchAccessibleFoods(user.getId(), "", PageRequest.of(0, 200)).getContent()
        );
        candidateFoods.sort(Comparator
                .comparing(FoodNutrition::getGi, Comparator.nullsLast(BigDecimal::compareTo))
                .thenComparing(FoodNutrition::getProteinGPer100g, Comparator.nullsLast(Comparator.reverseOrder())));

        List<FoodNutrition> selectedFoods = candidateFoods.stream()
                .filter(food -> food.getGi() == null || food.getGi().compareTo(new BigDecimal("55")) <= 0)
                .limit(4)
                .collect(Collectors.toCollection(ArrayList::new));

        if (summary.getTotalProteinG() != null && summary.getTotalProteinG().compareTo(new BigDecimal("60")) < 0) {
            candidateFoods.stream()
                    .filter(food -> food.getProteinGPer100g() != null && food.getProteinGPer100g().compareTo(new BigDecimal("10")) >= 0)
                    .limit(2)
                    .forEach(selectedFoods::add);
        }

        selectedFoods = selectedFoods.stream().distinct().limit(5).toList();

        List<String> tips = new ArrayList<>();
        BigDecimal totalCarb = summary.getTotalCarbG() == null ? BigDecimal.ZERO : summary.getTotalCarbG();
        BigDecimal totalProtein = summary.getTotalProteinG() == null ? BigDecimal.ZERO : summary.getTotalProteinG();
        BigDecimal totalCalorie = summary.getTotalCalorieKcal() == null ? BigDecimal.ZERO : summary.getTotalCalorieKcal();

        if (totalCarb.compareTo(new BigDecimal("220")) > 0) {
            tips.add("今天碳水偏高，下一餐建议优先选择低 GI 主食和高纤蔬菜。");
        } else {
            tips.add("今天碳水控制不错，继续保持主食均匀分配。");
        }

        if (totalProtein.compareTo(new BigDecimal("60")) < 0) {
            tips.add("蛋白质略少，可以补充鸡蛋、豆腐、鱼虾或无糖酸奶。");
        } else {
            tips.add("蛋白质摄入达标，继续搭配蔬菜帮助稳糖。");
        }

        if (profile != null && profile.getTargetPbgMax() != null) {
            tips.add("结合你的血糖目标，建议晚餐避免高糖水果和过量精制主食。");
        }

        String summaryText;
        if (totalCalorie.compareTo(new BigDecimal("1800")) > 0) {
            summaryText = "今天总热量偏高，推荐用低 GI 食物替换部分主食，并增加清淡优质蛋白。";
        } else if (totalCalorie.compareTo(new BigDecimal("1200")) < 0) {
            summaryText = "今天总热量偏低，建议增加优质蛋白和复合碳水，避免长时间空腹。";
        } else {
            summaryText = "今天饮食整体比较平衡，继续保持低 GI 主食、优质蛋白和蔬菜的搭配。";
        }

        DietDto.DailyRecommendationResponse response = new DietDto.DailyRecommendationResponse();
        response.setDate(date);
        response.setSummary(summaryText);
        response.setTips(tips);
        response.setRecommendedFoods(selectedFoods.stream().map(DietDto.FoodItemResponse::from).toList());
        return response;
    }

    private FoodNutrition findAccessibleFood(Long userId, Long foodId) {
        FoodNutrition food = foodNutritionRepository.findById(foodId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "食物不存在"));
        if (food.getUserId() != null && !food.getUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权访问该食物");
        }
        return food;
    }

    private DietRecord.MealType parseMealType(String value) {
        try {
            return DietRecord.MealType.valueOf(value.toUpperCase());
        } catch (Exception ex) {
            return DietRecord.MealType.SNACK;
        }
    }

    private BigDecimal scale(BigDecimal value, BigDecimal ratio) {
        if (value == null) {
            return null;
        }
        return value.multiply(ratio).setScale(2, RoundingMode.HALF_UP);
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

    private Map<Long, FoodNutrition> loadFoods(List<Long> foodIds) {
        Map<Long, FoodNutrition> result = new HashMap<>();
        if (foodIds.isEmpty()) {
            return result;
        }
        foodNutritionRepository.findAllById(foodIds)
                .forEach(food -> result.put(food.getId(), food));
        return result;
    }

    private DietDto.RecordResponse toRecordResponse(DietRecord record, String foodName) {
        DietDto.RecordResponse response = new DietDto.RecordResponse();
        response.setId(record.getId());
        response.setUserId(record.getUserId());
        response.setRecordDate(record.getRecordDate());
        response.setRecordTime(record.getRecordTime());
        response.setMealType(record.getMealType() != null ? record.getMealType().name() : null);
        response.setFoodId(record.getFoodId());
        response.setFoodName(foodName);
        response.setAmountG(record.getAmountG());
        response.setCalorieKcal(record.getCalorieKcal());
        response.setCarbG(record.getCarbG());
        response.setProteinG(record.getProteinG());
        response.setFatG(record.getFatG());
        response.setRemark(record.getRemark());
        response.setCreatedAt(record.getCreatedAt());
        return response;
    }
}
