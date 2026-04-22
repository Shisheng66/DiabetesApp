package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * 运动记录表
 */
@Entity
@Table(
        name = "exercise_record",
        indexes = {
                @Index(name = "idx_exercise_user_start_time", columnList = "user_id, start_time"),
                @Index(name = "idx_exercise_user_type", columnList = "user_id, exercise_type_id")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExerciseRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "exercise_type_id", nullable = false)
    private Long exerciseTypeId;

    @Column(name = "start_time", nullable = false)
    private Instant startTime;

    @Column(name = "end_time")
    private Instant endTime;

    @Column(name = "duration_min")
    private Integer durationMin;

    @Column(name = "distance_km", precision = 8, scale = 2)
    private BigDecimal distanceKm;

    @Column(name = "calorie_kcal", precision = 10, scale = 2)
    private BigDecimal calorieKcal;

    @Column(length = 200)
    private String remark;

    @Column(nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }
}
