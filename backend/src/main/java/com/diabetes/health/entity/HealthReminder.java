package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalTime;

/**
 * 健康提醒计划表
 */
@Entity
@Table(
        name = "health_reminder",
        indexes = {
                @Index(name = "idx_reminder_user_time", columnList = "user_id, time_of_day"),
                @Index(name = "idx_reminder_user_enabled", columnList = "user_id, enabled")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthReminder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ReminderType type;

    @Column(name = "time_of_day")  // 如 08:00
    private LocalTime timeOfDay;

    @Enumerated(EnumType.STRING)
    @Column(name = "repeat_type", length = 20)
    @Builder.Default
    private RepeatType repeatType = RepeatType.DAILY;

    @Column(nullable = false)
    @Builder.Default
    private Boolean enabled = true;

    @Column(length = 200)
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

    public enum ReminderType {
        GLUCOSE_TEST,  // 测血糖
        MEDICINE,      // 吃药
        EXERCISE,      // 运动
        DIET           // 饮食
    }

    public enum RepeatType {
        DAILY,         // 每天
        WORKDAY,       // 工作日
        CUSTOM         // 自定义（可扩展为周几）
    }
}
