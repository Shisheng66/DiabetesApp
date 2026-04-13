package com.diabetes.health.repository;

import com.diabetes.health.entity.GlucometerDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GlucometerDeviceRepository extends JpaRepository<GlucometerDevice, Long> {

    List<GlucometerDevice> findByUserIdAndBindStatus(Long userId, GlucometerDevice.BindStatus bindStatus);

    Optional<GlucometerDevice> findByUserIdAndDeviceSn(Long userId, String deviceSn);
}
