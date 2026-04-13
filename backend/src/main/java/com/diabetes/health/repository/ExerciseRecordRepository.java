package com.diabetes.health.repository;

import com.diabetes.health.entity.ExerciseRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface ExerciseRecordRepository extends JpaRepository<ExerciseRecord, Long> {

    List<ExerciseRecord> findByUserIdOrderByStartTimeDesc(Long userId, org.springframework.data.domain.Pageable pageable);

    List<ExerciseRecord> findByUserIdAndStartTimeBetweenOrderByStartTimeDesc(Long userId, Instant start, Instant end);
}
