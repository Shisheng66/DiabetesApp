package com.diabetes.health.repository;

import com.diabetes.health.entity.UserHealthProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface UserHealthProfileRepository extends JpaRepository<UserHealthProfile, Long> {

    Optional<UserHealthProfile> findByUserId(Long userId);

    List<UserHealthProfile> findAllByUserIdIn(Collection<Long> userIds);
}
