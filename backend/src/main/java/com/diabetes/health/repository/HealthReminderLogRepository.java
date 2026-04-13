package com.diabetes.health.repository;

import com.diabetes.health.entity.HealthReminderLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HealthReminderLogRepository extends JpaRepository<HealthReminderLog, Long> {
}
