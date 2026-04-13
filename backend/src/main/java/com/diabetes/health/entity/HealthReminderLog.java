package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * 提醒触发记录表
 */
@Entity
@Table(name = "health_reminder_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthReminderLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "reminder_id", nullable = false)
    private Long reminderId;

    @Column(name = "trigger_time", nullable = false)
    private Instant triggerTime;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    @Builder.Default
    private LogStatus status = LogStatus.PUSHED;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public enum LogStatus {
        PUSHED,   // 已推送
        CONFIRMED // 用户已确认
    }
}
