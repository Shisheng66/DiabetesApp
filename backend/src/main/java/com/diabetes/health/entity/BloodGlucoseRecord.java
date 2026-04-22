package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * 血糖记录表
 */
@Entity
@Table(
        name = "blood_glucose_record",
        indexes = {
                @Index(name = "idx_bg_user_measure_time", columnList = "user_id, measure_time"),
                @Index(name = "idx_bg_user_measure_type", columnList = "user_id, measure_type")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BloodGlucoseRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "measure_time", nullable = false)
    private Instant measureTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "measure_type", nullable = false, length = 20)
    private MeasureType measureType;

    @Column(name = "value_mmol_l", nullable = false, precision = 5, scale = 2)
    private BigDecimal valueMmolL;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RecordSource source;

    @Column(name = "device_id")
    private Long deviceId;

    @Column(length = 200)
    private String remark;

    @Enumerated(EnumType.STRING)
    @Column(name = "abnormal_flag", length = 20)
    @Builder.Default
    private AbnormalFlag abnormalFlag = AbnormalFlag.NORMAL;

    @Column(nullable = false)
    @Builder.Default
    private Boolean deleted = false;

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

    public enum MeasureType {
        FASTING,    // 空腹
        POST_MEAL,  // 餐后
        BEFORE_SLEEP, // 睡前
        RANDOM      // 随机
    }

    public enum RecordSource {
        MANUAL, BLE
    }

    public enum AbnormalFlag {
        NORMAL, HIGH, LOW
    }
}
