package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * User defined daily meal plan entry.
 */
@Entity
@Table(name = "daily_meal_plan")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyMealPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "plan_date", nullable = false)
    private LocalDate planDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false, length = 20)
    private DietRecord.MealType mealType;

    @Column(name = "food_id", nullable = false)
    private Long foodId;

    @Column(name = "amount_g", nullable = false, precision = 10, scale = 2)
    private BigDecimal amountG;

    @Column(length = 200)
    private String remark;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }
}
