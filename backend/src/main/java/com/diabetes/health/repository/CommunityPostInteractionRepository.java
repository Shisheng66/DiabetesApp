package com.diabetes.health.repository;

import com.diabetes.health.entity.CommunityPostInteraction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface CommunityPostInteractionRepository extends JpaRepository<CommunityPostInteraction, Long> {

    Optional<CommunityPostInteraction> findByPostIdAndUserId(Long postId, Long userId);

    List<CommunityPostInteraction> findByPostIdInAndUserId(Collection<Long> postIds, Long userId);

    Page<CommunityPostInteraction> findByUserIdAndLikedTrueOrderByUpdatedAtDesc(Long userId, Pageable pageable);

    Page<CommunityPostInteraction> findByUserIdAndFavoritedTrueOrderByUpdatedAtDesc(Long userId, Pageable pageable);

    long countByPostIdAndLikedTrue(Long postId);

    long countByPostIdAndFavoritedTrue(Long postId);
}
