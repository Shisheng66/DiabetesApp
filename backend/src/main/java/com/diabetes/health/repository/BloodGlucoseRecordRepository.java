package com.diabetes.health.repository;

import com.diabetes.health.entity.BloodGlucoseRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface BloodGlucoseRecordRepository extends JpaRepository<BloodGlucoseRecord, Long> {

    Page<BloodGlucoseRecord> findByUserIdOrderByMeasureTimeDesc(Long userId, Pageable pageable);

    @Query("SELECT r FROM BloodGlucoseRecord r WHERE r.userId = :userId AND r.measureTime >= :start AND r.measureTime < :end ORDER BY r.measureTime")
    List<BloodGlucoseRecord> findByUserIdAndMeasureTimeBetween(
            @Param("userId") Long userId,
            @Param("start") Instant start,
            @Param("end") Instant end
    );
}
