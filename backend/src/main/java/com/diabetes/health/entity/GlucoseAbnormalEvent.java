package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * 血糖异常事件表
 */
@Entity
@Table(name = "glucose_abnormal_event")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GlucoseAbnormalEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "record_id", nullable = false)
    private Long recordId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private EventType type;

    @Column(length = 20)
    private String level;  // 轻度/中度/重度 可选

    @Column(nullable = false)
    @Builder.Default
    private Boolean handled = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public enum EventType {
        HIGH, LOW
    }
}
