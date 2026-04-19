package com.diabetes.health.repository;

import com.diabetes.health.entity.CommunityComment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommunityCommentRepository extends JpaRepository<CommunityComment, Long> {

    Page<CommunityComment> findByPostIdOrderByCreatedAtAsc(Long postId, Pageable pageable);

    long countByPostId(Long postId);
}
