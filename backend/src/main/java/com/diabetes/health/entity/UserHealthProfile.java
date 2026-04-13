package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;

/**
 * 用户健康档案表
 */
@Entity
@Table(name = "user_health_profile")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserHealthProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    @Column(length = 50)
    private String nickname;

    @Column(length = 255)
    private String avatarUrl;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "height_cm")
    private Integer heightCm;

    @Column(name = "weight_kg")
    private java.math.BigDecimal weightKg;

    @Enumerated(EnumType.STRING)
    @Column(name = "diabetes_type", length = 30)
    private DiabetesType diabetesType;

    @Column(name = "diagnosis_date")
    private LocalDate diagnosisDate;

    @Column(name = "medication_status", length = 100)
    private String medicationStatus;

    @Column(name = "target_fbg_min")
    private java.math.BigDecimal targetFbgMin;

    @Column(name = "target_fbg_max")
    private java.math.BigDecimal targetFbgMax;

    @Column(name = "target_pbg_min")
    private java.math.BigDecimal targetPbgMin;

    @Column(name = "target_pbg_max")
    private java.math.BigDecimal targetPbgMax;

    @Column(length = 500)
    private String remark;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public enum Gender {
        MALE, FEMALE, UNKNOWN
    }

    public enum DiabetesType {
        TYPE1, TYPE2, GESTATIONAL, OTHER
    }
}
