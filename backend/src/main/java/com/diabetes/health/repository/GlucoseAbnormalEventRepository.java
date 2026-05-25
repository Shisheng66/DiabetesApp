package com.diabetes.health.repository;

import com.diabetes.health.entity.GlucoseAbnormalEvent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GlucoseAbnormalEventRepository extends JpaRepository<GlucoseAbnormalEvent, Long> {

    Page<GlucoseAbnormalEvent> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    Page<GlucoseAbnormalEvent> findByHandledFalseOrderByCreatedAtDesc(Pageable pageable);

    long countByUserId(Long userId);
}
