package com.diabetes.health.repository;

import com.diabetes.health.entity.DietRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DietRecordRepository extends JpaRepository<DietRecord, Long> {

    Optional<DietRecord> findByIdAndDeletedFalse(Long id);

    List<DietRecord> findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(Long userId, LocalDate recordDate);

    List<DietRecord> findByUserIdAndRecordDateAndMealTypeAndDeletedFalseOrderByRecordTimeDesc(
            Long userId, LocalDate recordDate, DietRecord.MealType mealType);
}
