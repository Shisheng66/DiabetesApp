package com.diabetes.health.repository;

import com.diabetes.health.entity.BloodGlucoseRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface BloodGlucoseRecordRepository extends JpaRepository<BloodGlucoseRecord, Long> {

    Page<BloodGlucoseRecord> findByUserIdAndDeletedFalseOrderByMeasureTimeDesc(Long userId, Pageable pageable);

    Optional<BloodGlucoseRecord> findByIdAndDeletedFalse(Long id);

    @Query(
            value = "SELECT r FROM BloodGlucoseRecord r WHERE r.userId = :userId AND r.deleted = false AND r.measureTime >= :start AND r.measureTime < :end ORDER BY r.measureTime DESC",
            countQuery = "SELECT COUNT(r) FROM BloodGlucoseRecord r WHERE r.userId = :userId AND r.deleted = false AND r.measureTime >= :start AND r.measureTime < :end"
    )
    Page<BloodGlucoseRecord> findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(
            @Param("userId") Long userId,
            @Param("start") Instant start,
            @Param("end") Instant end,
            Pageable pageable
    );

    @Query("SELECT r FROM BloodGlucoseRecord r WHERE r.userId = :userId AND r.deleted = false AND r.measureTime >= :start AND r.measureTime < :end ORDER BY r.measureTime DESC")
    List<BloodGlucoseRecord> findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(
            @Param("userId") Long userId,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

    @Query(
            value = "SELECT r FROM BloodGlucoseRecord r WHERE r.userId = :userId AND r.deleted = false AND r.measureType = :measureType AND r.measureTime >= :start AND r.measureTime < :end ORDER BY r.measureTime DESC",
            countQuery = "SELECT COUNT(r) FROM BloodGlucoseRecord r WHERE r.userId = :userId AND r.deleted = false AND r.measureType = :measureType AND r.measureTime >= :start AND r.measureTime < :end"
    )
    Page<BloodGlucoseRecord> findByUserIdAndMeasureTypeAndMeasureTimeBetweenOrderByMeasureTimeDesc(
            @Param("userId") Long userId,
            @Param("measureType") BloodGlucoseRecord.MeasureType measureType,
            @Param("start") Instant start,
            @Param("end") Instant end,
            Pageable pageable
    );
}
