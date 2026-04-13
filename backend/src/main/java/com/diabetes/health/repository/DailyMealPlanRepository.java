package com.diabetes.health.repository;

import com.diabetes.health.entity.DailyMealPlan;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface DailyMealPlanRepository extends JpaRepository<DailyMealPlan, Long> {

    List<DailyMealPlan> findByUserIdAndPlanDateOrderByMealTypeAscCreatedAtAsc(Long userId, LocalDate planDate);
}
