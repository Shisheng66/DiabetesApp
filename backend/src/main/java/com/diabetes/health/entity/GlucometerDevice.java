package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * 血糖仪设备表（含硅基等）
 */
@Entity
@Table(name = "glucometer_device")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GlucometerDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    @Builder.Default
    private Vendor vendor = Vendor.SILICON;

    @Column(name = "device_sn", nullable = false, length = 64)
    private String deviceSn;

    @Column(name = "device_name", length = 100)
    private String deviceName;

    @Enumerated(EnumType.STRING)
    @Column(name = "bind_status", nullable = false, length = 20)
    @Builder.Default
    private BindStatus bindStatus = BindStatus.BOUND;

    @Column(name = "bind_time")
    private Instant bindTime;

    @Column(name = "last_sync_time")
    private Instant lastSyncTime;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
        if (bindTime == null) bindTime = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public enum Vendor {
        SILICON  // 硅基
    }

    public enum BindStatus {
        BOUND, UNBOUND
    }
}
