package com.diabetes.health.repository;

import com.diabetes.health.entity.ExerciseRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ExerciseRecordRepository extends JpaRepository<ExerciseRecord, Long> {

    Optional<ExerciseRecord> findByIdAndDeletedFalse(Long id);

    List<ExerciseRecord> findByUserIdAndDeletedFalseOrderByStartTimeDesc(Long userId, org.springframework.data.domain.Pageable pageable);

    List<ExerciseRecord> findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(Long userId, Instant start, Instant end);
}
