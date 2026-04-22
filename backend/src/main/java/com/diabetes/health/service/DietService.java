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

    private static final BigDecimal FOUR = BigDecimal.valueOf(4);
    private static final BigDecimal NINE = BigDecimal.valueOf(9);
    private static final BigDecimal FIBER_TARGET_G = BigDecimal.valueOf(25);
    private static final Map<DietRecord.MealType, String> MEAL_LABELS = Map.of(
            DietRecord.MealType.BREAKFAST, "早餐",
            DietRecord.MealType.LUNCH, "午餐",
            DietRecord.MealType.DINNER, "晚餐",
            DietRecord.MealType.SNACK, "加餐"
    );

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

    public DietDto.NutritionAnalysisResponse getDailyNutritionAnalysis(CurrentUser user, LocalDate date) {
        List<DietRecord> records = dietRecordRepository.findByUserIdAndRecordDateOrderByRecordTimeDesc(user.getId(), date);
        Map<Long, FoodNutrition> foods = loadFoods(records.stream().map(DietRecord::getFoodId).toList());

        BigDecimal totalCalorie = sum(records.stream().map(DietRecord::getCalorieKcal).toList());
        BigDecimal totalCarb = sum(records.stream().map(DietRecord::getCarbG).toList());
        BigDecimal totalProtein = sum(records.stream().map(DietRecord::getProteinG).toList());
        BigDecimal totalFat = sum(records.stream().map(DietRecord::getFatG).toList());
        BigDecimal macroCalories = totalCarb.multiply(FOUR)
                .add(totalProtein.multiply(FOUR))
                .add(totalFat.multiply(NINE));

        BigDecimal carbShare = pct(totalCarb.multiply(FOUR), macroCalories);
        BigDecimal proteinShare = pct(totalProtein.multiply(FOUR), macroCalories);
        BigDecimal fatShare = pct(totalFat.multiply(NINE), macroCalories);
        BigDecimal estimatedFiber = estimateFiber(records, foods);
        BigDecimal averageGi = averageGi(records, foods);

        List<String> riskFlags = new ArrayList<>();
        List<String> insights = new ArrayList<>();
        List<String> actions = new ArrayList<>();
        int score = 100;

        if (records.isEmpty()) {
            score = 55;
            insights.add("今天还没有饮食记录，营养管家只能给出基础建议。");
            actions.add("先记录一餐，系统会自动分析热量、碳水比例和餐次结构。");
        }

        if (totalCalorie.compareTo(BigDecimal.valueOf(2200)) > 0) {
            score -= 12;
            riskFlags.add("今日总热量偏高");
            actions.add("下一餐减少油脂和主食份量，优先蔬菜与清蒸/水煮蛋白。");
        } else if (!records.isEmpty() && totalCalorie.compareTo(BigDecimal.valueOf(1000)) < 0) {
            score -= 8;
            riskFlags.add("今日能量偏低");
            actions.add("避免长时间空腹，可增加鸡蛋、豆腐、鱼虾或无糖酸奶。");
        }

        if (carbShare.compareTo(BigDecimal.valueOf(55)) > 0 || totalCarb.compareTo(BigDecimal.valueOf(230)) > 0) {
            score -= 14;
            riskFlags.add("碳水占比偏高");
            actions.add("把精制主食替换为糙米、燕麦、红薯或杂豆，单餐主食控制在拳头大小。");
        } else if (carbShare.compareTo(BigDecimal.valueOf(35)) < 0 && !records.isEmpty()) {
            score -= 5;
            insights.add("碳水比例偏低，注意不要因过度控糖造成低血糖风险。");
        } else if (!records.isEmpty()) {
            insights.add("碳水比例处在相对稳糖区间，有利于减少餐后波动。");
        }

        if (totalProtein.compareTo(BigDecimal.valueOf(50)) < 0 && !records.isEmpty()) {
            score -= 10;
            riskFlags.add("蛋白质不足");
            actions.add("每餐补足一掌心优质蛋白，如鸡蛋、鱼虾、鸡胸、豆腐或无糖酸奶。");
        } else if (!records.isEmpty()) {
            insights.add("蛋白质摄入有助于延缓胃排空，提升餐后血糖稳定性。");
        }

        int fiberPct = achievementPct(estimatedFiber, FIBER_TARGET_G);
        if (fiberPct < 60 && !records.isEmpty()) {
            score -= 12;
            riskFlags.add("膳食纤维不足");
            actions.add("下一餐增加两份深色蔬菜，主食加入燕麦、杂豆或全谷物。");
        } else if (!records.isEmpty()) {
            insights.add("膳食纤维越接近 25g/天，越有利于餐后血糖平稳。");
        }

        if (averageGi != null && averageGi.compareTo(BigDecimal.valueOf(60)) > 0) {
            score -= 10;
            riskFlags.add("食物 GI 均值偏高");
            actions.add("优先选择低 GI 食物，避免白粥、甜点、含糖饮料和大量精米面。");
        }

        score = Math.max(0, Math.min(100, score));

        DietDto.NutritionAnalysisResponse response = new DietDto.NutritionAnalysisResponse();
        response.setDate(date);
        response.setScore(score);
        response.setGrade(grade(score));
        response.setHeadline(headline(score, riskFlags));
        response.setSummary(summary(score, totalCalorie, totalCarb, estimatedFiber));
        response.setTotalCalorieKcal(totalCalorie);
        response.setEstimatedFiberG(estimatedFiber);
        response.setFiberAchievementPct(fiberPct);
        response.setAverageGi(averageGi);
        response.setRiskFlags(riskFlags);
        response.setInsights(insights.stream().limit(4).toList());
        response.setActionItems(actions.stream().distinct().limit(4).toList());
        response.setMacroBalance(List.of(
                macro("carb", "碳水", totalCarb, carbShare, BigDecimal.valueOf(35), BigDecimal.valueOf(50)),
                macro("protein", "蛋白质", totalProtein, proteinShare, BigDecimal.valueOf(15), BigDecimal.valueOf(25)),
                macro("fat", "脂肪", totalFat, fatShare, BigDecimal.valueOf(20), BigDecimal.valueOf(35))
        ));
        response.setMealBalance(mealBalance(records));
        response.setNextMealAdvice(nextMealAdvice(riskFlags, records));
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

    private DietDto.MacroBalanceItem macro(
            String key,
            String label,
            BigDecimal grams,
            BigDecimal share,
            BigDecimal targetMin,
            BigDecimal targetMax
    ) {
        DietDto.MacroBalanceItem item = new DietDto.MacroBalanceItem();
        item.setKey(key);
        item.setLabel(label);
        item.setGrams(grams);
        item.setCalorieSharePct(share);
        item.setTargetMinPct(targetMin);
        item.setTargetMaxPct(targetMax);
        item.setStatus(share.compareTo(targetMin) < 0 ? "LOW" : (share.compareTo(targetMax) > 0 ? "HIGH" : "OK"));
        return item;
    }

    private List<DietDto.MealBalanceItem> mealBalance(List<DietRecord> records) {
        List<DietDto.MealBalanceItem> items = new ArrayList<>();
        for (DietRecord.MealType mealType : DietRecord.MealType.values()) {
            List<DietRecord> mealRecords = records.stream()
                    .filter(record -> record.getMealType() == mealType)
                    .toList();
            BigDecimal calorie = sum(mealRecords.stream().map(DietRecord::getCalorieKcal).toList());
            BigDecimal carb = sum(mealRecords.stream().map(DietRecord::getCarbG).toList());
            BigDecimal protein = sum(mealRecords.stream().map(DietRecord::getProteinG).toList());
            BigDecimal fat = sum(mealRecords.stream().map(DietRecord::getFatG).toList());

            DietDto.MealBalanceItem item = new DietDto.MealBalanceItem();
            item.setMealType(mealType.name());
            item.setMealLabel(MEAL_LABELS.getOrDefault(mealType, mealType.name()));
            item.setCalorieKcal(calorie);
            item.setCarbG(carb);
            item.setProteinG(protein);
            item.setFatG(fat);
            item.setRecordCount(mealRecords.size());
            item.setStatus(mealRecords.isEmpty() ? "EMPTY" : (carb.compareTo(BigDecimal.valueOf(90)) > 0 ? "CARB_HIGH" : "OK"));
            items.add(item);
        }
        return items;
    }

    private BigDecimal estimateFiber(List<DietRecord> records, Map<Long, FoodNutrition> foods) {
        BigDecimal result = BigDecimal.ZERO;
        for (DietRecord record : records) {
            BigDecimal carb = record.getCarbG() == null ? BigDecimal.ZERO : record.getCarbG();
            FoodNutrition food = foods.get(record.getFoodId());
            BigDecimal ratio = fiberRatio(food == null ? null : food.getCategory());
            result = result.add(carb.multiply(ratio));
        }
        return result.setScale(1, RoundingMode.HALF_UP);
    }

    private BigDecimal averageGi(List<DietRecord> records, Map<Long, FoodNutrition> foods) {
        BigDecimal weightedGi = BigDecimal.ZERO;
        BigDecimal totalAmount = BigDecimal.ZERO;
        for (DietRecord record : records) {
            FoodNutrition food = foods.get(record.getFoodId());
            if (food == null || food.getGi() == null || record.getAmountG() == null) {
                continue;
            }
            weightedGi = weightedGi.add(food.getGi().multiply(record.getAmountG()));
            totalAmount = totalAmount.add(record.getAmountG());
        }
        if (totalAmount.compareTo(BigDecimal.ZERO) <= 0) {
            return null;
        }
        return weightedGi.divide(totalAmount, 1, RoundingMode.HALF_UP);
    }

    private BigDecimal fiberRatio(String category) {
        String text = category == null ? "" : category.toLowerCase();
        if (text.contains("蔬菜") || text.contains("vegetable")) return BigDecimal.valueOf(0.45);
        if (text.contains("水果") || text.contains("fruit")) return BigDecimal.valueOf(0.28);
        if (text.contains("主食") || text.contains("谷") || text.contains("grain")) return BigDecimal.valueOf(0.12);
        if (text.contains("豆") || text.contains("legume")) return BigDecimal.valueOf(0.22);
        if (text.contains("坚果") || text.contains("nut")) return BigDecimal.valueOf(0.15);
        return BigDecimal.valueOf(0.06);
    }

    private BigDecimal pct(BigDecimal value, BigDecimal total) {
        if (value == null || total == null || total.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        return value.multiply(BigDecimal.valueOf(100)).divide(total, 1, RoundingMode.HALF_UP);
    }

    private int achievementPct(BigDecimal actual, BigDecimal target) {
        if (actual == null || target == null || target.compareTo(BigDecimal.ZERO) <= 0) {
            return 0;
        }
        return actual.multiply(BigDecimal.valueOf(100)).divide(target, 0, RoundingMode.HALF_UP).intValue();
    }

    private String grade(int score) {
        if (score >= 85) return "优秀";
        if (score >= 70) return "良好";
        if (score >= 55) return "一般";
        return "需关注";
    }

    private String headline(int score, List<String> riskFlags) {
        if (riskFlags.isEmpty() && score >= 80) {
            return "今天的饮食结构很稳，继续保持低波动节奏";
        }
        if (riskFlags.contains("碳水占比偏高")) {
            return "今天需要控碳，下一餐先稳住餐后血糖";
        }
        if (riskFlags.contains("膳食纤维不足")) {
            return "今天纤维偏少，下一餐要把蔬菜和全谷物补上";
        }
        return "营养管家已给出下一餐优先级";
    }

    private String summary(int score, BigDecimal calories, BigDecimal carb, BigDecimal fiber) {
        return "营养评分 " + score + " 分；已记录 " + calories.setScale(0, RoundingMode.HALF_UP)
                + " kcal，碳水 " + carb.setScale(0, RoundingMode.HALF_UP)
                + "g，估算纤维 " + fiber + "g。";
    }

    private String nextMealAdvice(List<String> riskFlags, List<DietRecord> records) {
        if (records.isEmpty()) {
            return "先记录今天第一餐，建议从早餐开始：蛋白质 + 全谷物 + 一份蔬菜或低糖水果。";
        }
        if (riskFlags.contains("碳水占比偏高")) {
            return "下一餐建议：半份主食 + 两份蔬菜 + 一掌心蛋白，避免含糖饮料。";
        }
        if (riskFlags.contains("蛋白质不足")) {
            return "下一餐建议优先补蛋白：鸡蛋、鱼虾、鸡胸、豆腐或无糖酸奶任选一种。";
        }
        if (riskFlags.contains("膳食纤维不足")) {
            return "下一餐建议先补纤维：深色蔬菜、燕麦、杂豆或红薯搭配优质蛋白。";
        }
        return "下一餐保持当前节奏：低 GI 主食、足量蛋白、蔬菜先吃，饭后轻走 15-20 分钟。";
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
        List<Long> safeFoodIds = foodIds.stream()
                .filter(java.util.Objects::nonNull)
                .distinct()
                .toList();
        if (safeFoodIds.isEmpty()) {
            return result;
        }
        foodNutritionRepository.findAllById(safeFoodIds)
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
