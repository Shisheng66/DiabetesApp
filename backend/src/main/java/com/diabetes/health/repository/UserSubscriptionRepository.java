package com.diabetes.health.repository;

import com.diabetes.health.entity.UserSubscription;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Optional;

public interface UserSubscriptionRepository extends JpaRepository<UserSubscription, Long> {
    Optional<UserSubscription> findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
            Long userId,
            UserSubscription.SubscriptionStatus status,
            Instant now
    );
}
