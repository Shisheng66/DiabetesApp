package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Food nutrition data per 100g. Shared foods have a null userId, while
 * custom foods belong to a specific user.
 */
@Entity
@Table(name = "food_nutrition")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FoodNutrition {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "custom_food", nullable = false)
    @Builder.Default
    private Boolean customFood = false;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 50)
    private String category;

    @Column(name = "calorie_kcal_per_100g", precision = 8, scale = 2)
    private BigDecimal calorieKcalPer100g;

    @Column(name = "carb_g_per_100g", precision = 8, scale = 2)
    private BigDecimal carbGPer100g;

    @Column(name = "protein_g_per_100g", precision = 8, scale = 2)
    private BigDecimal proteinGPer100g;

    @Column(name = "fat_g_per_100g", precision = 8, scale = 2)
    private BigDecimal fatGPer100g;

    @Column(precision = 5, scale = 2)
    private BigDecimal gi;
}
