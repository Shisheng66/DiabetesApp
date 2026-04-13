package com.diabetes.health.repository;

import com.diabetes.health.entity.FoodNutrition;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FoodNutritionRepository extends JpaRepository<FoodNutrition, Long> {

    List<FoodNutrition> findByUserIdIsNullAndNameContainingIgnoreCase(String keyword);

    List<FoodNutrition> findByUserIdAndNameContainingIgnoreCase(Long userId, String keyword);
}
