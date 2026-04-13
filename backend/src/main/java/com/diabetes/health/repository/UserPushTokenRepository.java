package com.diabetes.health.repository;

import com.diabetes.health.entity.UserPushToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserPushTokenRepository extends JpaRepository<UserPushToken, Long> {

    List<UserPushToken> findByUserId(Long userId);

    Optional<UserPushToken> findByUserIdAndPushToken(Long userId, String pushToken);
}
