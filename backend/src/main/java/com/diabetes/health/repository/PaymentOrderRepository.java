package com.diabetes.health.repository;

import com.diabetes.health.entity.PaymentOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PaymentOrderRepository extends JpaRepository<PaymentOrder, Long> {
    Optional<PaymentOrder> findByOrderNoAndUserId(String orderNo, Long userId);
    Page<PaymentOrder> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
}
