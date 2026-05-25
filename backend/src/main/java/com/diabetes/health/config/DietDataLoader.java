package com.diabetes.health.config;

import com.diabetes.health.entity.FoodNutrition;
import com.diabetes.health.repository.FoodNutritionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

/**
 * Seeds shared food data on the first startup.
 */
@Component
@RequiredArgsConstructor
public class DietDataLoader implements ApplicationRunner {

    private final FoodNutritionRepository foodNutritionRepository;

    @Override
    public void run(ApplicationArguments args) {
        if (foodNutritionRepository.count() > 0) {
            return;
        }

        List<FoodNutrition> foods = List.of(
                food("米饭", "主食", "116", "25.9", "2.6", "0.3", "90"),
                food("糙米饭", "主食", "111", "23.0", "2.6", "0.9", "55"),
                food("燕麦", "主食", "389", "66.2", "16.9", "6.9", "55"),
                food("红薯", "主食", "86", "20.1", "1.6", "0.1", "54"),
                food("鸡蛋", "蛋类", "155", "1.1", "13.0", "11.0", null),
                food("鸡胸肉", "蛋白质", "133", "0.0", "24.0", "2.0", null),
                food("豆腐", "蛋白质", "81", "1.9", "8.1", "4.2", "15"),
                food("三文鱼", "蛋白质", "208", "0.0", "20.4", "13.4", null),
                food("虾仁", "蛋白质", "99", "0.2", "24.6", "0.3", null),
                food("西兰花", "蔬菜", "34", "6.6", "2.8", "0.4", "15"),
                food("黄瓜", "蔬菜", "15", "3.6", "0.7", "0.1", "15"),
                food("番茄", "蔬菜", "18", "3.9", "0.9", "0.2", "15"),
                food("苹果", "水果", "52", "13.8", "0.3", "0.2", "36"),
                food("蓝莓", "水果", "57", "14.5", "0.7", "0.3", "53"),
                food("无糖酸奶", "乳制品", "72", "5.0", "3.5", "3.2", "35"),
                food("牛奶", "乳制品", "54", "3.4", "3.0", "3.2", "32")
        );

        foodNutritionRepository.saveAll(foods);
    }

    private FoodNutrition food(
            String name,
            String category,
            String calorie,
            String carb,
            String protein,
            String fat,
            String gi) {
        return FoodNutrition.builder()
                .name(name)
                .category(category)
                .calorieKcalPer100g(new BigDecimal(calorie))
                .carbGPer100g(new BigDecimal(carb))
                .proteinGPer100g(new BigDecimal(protein))
                .fatGPer100g(new BigDecimal(fat))
                .gi(gi == null ? null : new BigDecimal(gi))
                .customFood(false)
                .build();
    }
}
