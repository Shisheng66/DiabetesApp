package com.diabetes.health.repository;

import com.diabetes.health.entity.HealthReminder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HealthReminderRepository extends JpaRepository<HealthReminder, Long> {

    List<HealthReminder> findByUserIdOrderByTimeOfDayAsc(Long userId);

    List<HealthReminder> findByUserIdAndEnabledTrueOrderByTimeOfDayAsc(Long userId);
}
