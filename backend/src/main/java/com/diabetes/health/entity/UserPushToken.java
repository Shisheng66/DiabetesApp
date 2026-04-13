package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * 用户设备推送 token 表（用于 APP 通知）
 */
@Entity
@Table(name = "user_push_token")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPushToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "device_type", length = 20)
    private String deviceType;  // ANDROID, IOS

    @Column(name = "push_token", nullable = false, length = 500)
    private String pushToken;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        if (updatedAt == null) updatedAt = Instant.now();
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public void touch() {
        updatedAt = Instant.now();
    }
}
