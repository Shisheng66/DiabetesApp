package com.diabetes.health.controller;

import com.diabetes.health.dto.DietDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.DietService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/diet")
@RequiredArgsConstructor
public class DietController {

    private final DietService dietService;

    @PostMapping("/records")
    public DietDto.RecordResponse create(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody DietDto.CreateRecordRequest request) {
        return dietService.create(user, request);
    }

    @GetMapping("/records")
    public List<DietDto.RecordResponse> list(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String mealType) {
        return dietService.listByDate(user, date, mealType);
    }

    @GetMapping("/summary/daily")
    public DietDto.DailySummaryResponse dailySummary(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return dietService.getDailySummary(user, date);
    }

    @GetMapping("/analysis/daily")
    public DietDto.NutritionAnalysisResponse dailyAnalysis(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return dietService.getDailyNutritionAnalysis(user, date);
    }

    @DeleteMapping("/records/{id}")
    public void delete(@AuthenticationPrincipal CurrentUser user, @PathVariable Long id) {
        dietService.delete(user, id);
    }

    @PutMapping("/records/{id}")
    public DietDto.RecordResponse update(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long id,
            @Valid @RequestBody DietDto.UpdateRecordRequest request) {
        return dietService.update(user, id, request);
    }

    @GetMapping("/foods")
    public DietDto.PageResult<DietDto.FoodItemResponse> searchFoods(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return dietService.searchFoods(user, keyword, page, size);
    }

    @PostMapping("/foods")
    public DietDto.FoodItemResponse createFood(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody DietDto.CreateFoodRequest request) {
        return dietService.createFood(user, request);
    }

    @GetMapping("/meal-plans")
    public DietDto.DailyMealPlanResponse mealPlans(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return dietService.getDailyMealPlan(user, date);
    }

    @PostMapping("/meal-plans")
    public DietDto.MealPlanItemResponse createMealPlan(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody DietDto.CreateMealPlanRequest request) {
        return dietService.createMealPlan(user, request);
    }

    @DeleteMapping("/meal-plans/{id}")
    public void deleteMealPlan(@AuthenticationPrincipal CurrentUser user, @PathVariable Long id) {
        dietService.deleteMealPlan(user, id);
    }

    @GetMapping("/recommendations/daily")
    public DietDto.DailyRecommendationResponse dailyRecommendation(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return dietService.getDailyRecommendation(user, date);
    }
}
