package com.diabetes.health.service;

import com.diabetes.health.dto.DietDto;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.FoodNutrition;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.*;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DietServiceTest {

    @Mock private DietRecordRepository dietRecordRepository;
    @Mock private FoodNutritionRepository foodNutritionRepository;
    @Mock private DailyMealPlanRepository dailyMealPlanRepository;
    @Mock private UserHealthProfileRepository userHealthProfileRepository;
    @InjectMocks private DietService dietService;

    private CurrentUser currentUser() {
        return new CurrentUser(1L, "13800138000", "PATIENT");
    }

    private FoodNutrition rice() {
        return FoodNutrition.builder()
                .id(10L).name("米饭").category("主食")
                .calorieKcalPer100g(new BigDecimal("116.00"))
                .carbGPer100g(new BigDecimal("25.60"))
                .proteinGPer100g(new BigDecimal("2.60"))
                .fatGPer100g(new BigDecimal("0.30"))
                .gi(new BigDecimal("83")).build();
    }

    @Test
    void createFood_customFood_succeeds() {
        when(foodNutritionRepository.save(any())).thenAnswer(inv -> {
            FoodNutrition f = inv.getArgument(0);
            f.setId(100L);
            return f;
        });

        DietDto.CreateFoodRequest req = new DietDto.CreateFoodRequest();
        req.setName("自制沙拉");
        req.setCategory("蔬菜");
        req.setCalorieKcalPer100g(new BigDecimal("45"));
        req.setCarbGPer100g(new BigDecimal("5"));
        req.setProteinGPer100g(new BigDecimal("2"));
        req.setFatGPer100g(new BigDecimal("3"));

        var result = dietService.createFood(currentUser(), req);
        assertThat(result.getName()).isEqualTo("自制沙拉");
        assertThat(result.getCustomFood()).isTrue();
        verify(foodNutritionRepository).save(argThat(f ->
                f.getUserId().equals(1L) && Boolean.TRUE.equals(f.getCustomFood())));
    }

    @Test
    void create_scalesNutritionByAmount() {
        FoodNutrition food = rice();
        when(foodNutritionRepository.findById(10L)).thenReturn(Optional.of(food));
        when(dietRecordRepository.save(any())).thenAnswer(inv -> {
            DietRecord r = inv.getArgument(0);
            r.setId(1L);
            return r;
        });

        DietDto.CreateRecordRequest req = new DietDto.CreateRecordRequest();
        req.setRecordDate(LocalDate.now());
        req.setMealType("BREAKFAST");
        req.setFoodId(10L);
        req.setAmountG(new BigDecimal("200"));

        var result = dietService.create(currentUser(), req);
        // 116 * 200/100 = 232.00
        assertThat(result.getCalorieKcal()).isEqualByComparingTo("232.00");
        // 25.6 * 2 = 51.20
        assertThat(result.getCarbG()).isEqualByComparingTo("51.20");
    }

    @Test
    void create_foodNotFound_throws404() {
        when(foodNutritionRepository.findById(99L)).thenReturn(Optional.empty());

        DietDto.CreateRecordRequest req = new DietDto.CreateRecordRequest();
        req.setRecordDate(LocalDate.now());
        req.setMealType("BREAKFAST");
        req.setFoodId(99L);
        req.setAmountG(new BigDecimal("100"));

        assertThatThrownBy(() -> dietService.create(currentUser(), req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void create_otherUsersPrivateFood_throws403() {
        FoodNutrition food = FoodNutrition.builder()
                .id(10L).userId(999L).name("私有食物").customFood(true)
                .calorieKcalPer100g(new BigDecimal("100"))
                .carbGPer100g(new BigDecimal("20"))
                .proteinGPer100g(new BigDecimal("5"))
                .fatGPer100g(new BigDecimal("3")).build();
        when(foodNutritionRepository.findById(10L)).thenReturn(Optional.of(food));

        DietDto.CreateRecordRequest req = new DietDto.CreateRecordRequest();
        req.setRecordDate(LocalDate.now());
        req.setMealType("BREAKFAST");
        req.setFoodId(10L);
        req.setAmountG(new BigDecimal("100"));

        assertThatThrownBy(() -> dietService.create(currentUser(), req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void listByDate_returnsRecordsWithFoodNames() {
        FoodNutrition food = rice();
        DietRecord record = DietRecord.builder()
                .id(1L).userId(1L).recordDate(LocalDate.now())
                .mealType(DietRecord.MealType.BREAKFAST).foodId(10L)
                .amountG(new BigDecimal("200"))
                .calorieKcal(new BigDecimal("232.00")).deleted(false).build();

        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, LocalDate.now()))
                .thenReturn(List.of(record));
        when(foodNutritionRepository.findAllById(List.of(10L))).thenReturn(List.of(food));

        var result = dietService.listByDate(currentUser(), LocalDate.now(), null);
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getFoodName()).isEqualTo("米饭");
    }

    @Test
    void delete_softDeletes() {
        DietRecord record = DietRecord.builder()
                .id(1L).userId(1L).deleted(false).build();
        when(dietRecordRepository.findByIdAndDeletedFalse(1L)).thenReturn(Optional.of(record));
        when(dietRecordRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        dietService.delete(currentUser(), 1L);
        verify(dietRecordRepository).save(argThat(r -> Boolean.TRUE.equals(r.getDeleted())));
    }

    @Test
    void delete_notFound_throws404() {
        when(dietRecordRepository.findByIdAndDeletedFalse(99L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> dietService.delete(currentUser(), 99L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void delete_notOwned_throws403() {
        DietRecord record = DietRecord.builder()
                .id(1L).userId(999L).deleted(false).build();
        when(dietRecordRepository.findByIdAndDeletedFalse(1L)).thenReturn(Optional.of(record));

        assertThatThrownBy(() -> dietService.delete(currentUser(), 1L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void getDailySummary_emptyDay_returnsZeroes() {
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, LocalDate.now()))
                .thenReturn(List.of());

        var result = dietService.getDailySummary(currentUser(), LocalDate.now());
        assertThat(result.getTotalCalorieKcal()).isEqualByComparingTo("0.00");
        assertThat(result.getTotalCarbG()).isEqualByComparingTo("0.00");
    }

    @Test
    void getDailySummary_withRecords_sumsCorrectly() {
        DietRecord r1 = DietRecord.builder()
                .foodId(10L).calorieKcal(new BigDecimal("232.00"))
                .carbG(new BigDecimal("51.20")).proteinG(new BigDecimal("5.20"))
                .fatG(new BigDecimal("0.60")).build();
        DietRecord r2 = DietRecord.builder()
                .foodId(10L).calorieKcal(new BigDecimal("116.00"))
                .carbG(new BigDecimal("25.60")).proteinG(new BigDecimal("2.60"))
                .fatG(new BigDecimal("0.30")).build();

        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, LocalDate.now()))
                .thenReturn(List.of(r1, r2));
        when(foodNutritionRepository.findAllById(any())).thenReturn(List.of(rice()));

        var result = dietService.getDailySummary(currentUser(), LocalDate.now());
        assertThat(result.getTotalCalorieKcal()).isEqualByComparingTo("348.00");
        assertThat(result.getTotalCarbG()).isEqualByComparingTo("76.80");
    }

    @Test
    void getDailyNutritionAnalysis_emptyDay_lowScore() {
        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, LocalDate.now()))
                .thenReturn(List.of());

        var result = dietService.getDailyNutritionAnalysis(currentUser(), LocalDate.now());
        assertThat(result.getScore()).isEqualTo(55);
        assertThat(result.getRiskFlags()).isEmpty();
        assertThat(result.getInsights()).isNotEmpty();
    }

    @Test
    void searchFoods_returnsPagedResults() {
        FoodNutrition food = rice();
        Page<FoodNutrition> page = new PageImpl<>(List.of(food), PageRequest.of(0, 10), 1);
        when(foodNutritionRepository.searchAccessibleFoods(1L, "米饭", PageRequest.of(0, 10))).thenReturn(page);

        var result = dietService.searchFoods(currentUser(), "米饭", 0, 10);
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getTotalElements()).isEqualTo(1);
    }

    @Test
    void deleteMealPlan_notFound_throws404() {
        when(dailyMealPlanRepository.findById(99L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> dietService.deleteMealPlan(currentUser(), 99L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void deleteMealPlan_notOwned_throws403() {
        com.diabetes.health.entity.DailyMealPlan plan = com.diabetes.health.entity.DailyMealPlan.builder()
                .id(1L).userId(999L).build();
        when(dailyMealPlanRepository.findById(1L)).thenReturn(Optional.of(plan));

        assertThatThrownBy(() -> dietService.deleteMealPlan(currentUser(), 1L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void deleteMealPlan_owned_deletes() {
        com.diabetes.health.entity.DailyMealPlan plan = com.diabetes.health.entity.DailyMealPlan.builder()
                .id(1L).userId(1L).build();
        when(dailyMealPlanRepository.findById(1L)).thenReturn(Optional.of(plan));

        dietService.deleteMealPlan(currentUser(), 1L);
        verify(dailyMealPlanRepository).delete(plan);
    }
}
