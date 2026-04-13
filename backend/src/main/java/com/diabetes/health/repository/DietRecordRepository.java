package com.diabetes.health.repository;

import com.diabetes.health.entity.DietRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface DietRecordRepository extends JpaRepository<DietRecord, Long> {

    List<DietRecord> findByUserIdAndRecordDateOrderByRecordTimeDesc(Long userId, LocalDate recordDate);

    List<DietRecord> findByUserIdAndRecordDateAndMealTypeOrderByRecordTimeDesc(
            Long userId, LocalDate recordDate, DietRecord.MealType mealType);
}
