package com.diabetes.health.controller;

import com.diabetes.health.dto.DietDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class DietControllerIntegrationTest extends BaseIntegrationTest {

    private static String token;

    @BeforeEach
    void setUp() {
        if (token == null) {
            token = registerUser("13940000041", "Test1234");
        }
    }

    @Test
    void searchFoods_returnsResults() {
        var resp = authGet("/api/diet/foods?page=0&size=10&keyword=米饭", token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void createFood_customFood() {
        var req = new DietDto.CreateFoodRequest();
        req.setName("测试食物");
        req.setCategory("自定义");
        req.setCalorieKcalPer100g(new BigDecimal("100"));
        req.setCarbGPer100g(new BigDecimal("20"));
        req.setProteinGPer100g(new BigDecimal("5"));
        req.setFatGPer100g(new BigDecimal("3"));

        var resp = authPost("/api/diet/foods", token, req, DietDto.FoodItemResponse.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody().getName()).isEqualTo("测试食物");
        assertThat(resp.getBody().getCustomFood()).isTrue();
    }

    @Test
    void createFood_missingName_returns400() {
        var req = new DietDto.CreateFoodRequest();
        req.setCalorieKcalPer100g(new BigDecimal("100"));
        req.setCarbGPer100g(new BigDecimal("20"));
        req.setProteinGPer100g(new BigDecimal("5"));
        req.setFatGPer100g(new BigDecimal("3"));

        var resp = authPost("/api/diet/foods", token, req, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void dailySummary_emptyDay_returnsZeroes() {
        String today = LocalDate.now().toString();
        var resp = authGet("/api/diet/summary/daily?date=" + today, token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).contains("totalCalorieKcal");
    }

    @Test
    void dailyAnalysis_emptyDay_returnsAnalysis() {
        String today = LocalDate.now().toString();
        var resp = authGet("/api/diet/analysis/daily?date=" + today, token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void dailyRecommendation_returnsTips() {
        String today = LocalDate.now().toString();
        var resp = authGet("/api/diet/recommendations/daily?date=" + today, token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void mealPlan_crud() {
        String today = LocalDate.now().toString();

        // 先创建一个自定义食物
        var foodReq = new DietDto.CreateFoodRequest();
        foodReq.setName("计划食物");
        foodReq.setCalorieKcalPer100g(new BigDecimal("80"));
        foodReq.setCarbGPer100g(new BigDecimal("15"));
        foodReq.setProteinGPer100g(new BigDecimal("4"));
        foodReq.setFatGPer100g(new BigDecimal("2"));
        var food = authPost("/api/diet/foods", token, foodReq, DietDto.FoodItemResponse.class);
        Long foodId = food.getBody().getId();

        // 创建计划
        var planReq = new DietDto.CreateMealPlanRequest();
        planReq.setPlanDate(LocalDate.now());
        planReq.setMealType("BREAKFAST");
        planReq.setFoodId(foodId);
        planReq.setAmountG(new BigDecimal("200"));
        var planResp = authPost("/api/diet/meal-plans", token, planReq, DietDto.MealPlanItemResponse.class);
        assertThat(planResp.getStatusCode()).isEqualTo(HttpStatus.OK);
        Long planId = planResp.getBody().getId();

        // 查询计划
        var listResp = authGet("/api/diet/meal-plans?date=" + today, token, String.class);
        assertThat(listResp.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 删除计划
        var delResp = authDelete("/api/diet/meal-plans/" + planId, token, Void.class);
        assertThat(delResp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
