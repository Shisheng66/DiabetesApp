package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * 饮食记录表
 */
@Entity
@Table(
        name = "diet_record",
        indexes = {
                @Index(name = "idx_diet_user_record_date", columnList = "user_id, record_date"),
                @Index(name = "idx_diet_user_record_time", columnList = "user_id, record_time")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DietRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "record_date", nullable = false)
    private LocalDate recordDate;

    @Column(name = "record_time")
    private Instant recordTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false, length = 20)
    private MealType mealType;

    @Column(name = "food_id", nullable = false)
    private Long foodId;

    @Column(name = "amount_g", nullable = false, precision = 10, scale = 2)
    private BigDecimal amountG;

    @Column(name = "calorie_kcal", precision = 10, scale = 2)
    private BigDecimal calorieKcal;

    @Column(name = "carb_g", precision = 10, scale = 2)
    private BigDecimal carbG;

    @Column(name = "protein_g", precision = 10, scale = 2)
    private BigDecimal proteinG;

    @Column(name = "fat_g", precision = 10, scale = 2)
    private BigDecimal fatG;

    @Column(length = 200)
    private String remark;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public enum MealType {
        BREAKFAST, LUNCH, DINNER, SNACK
    }
}
