package com.diabetes.health.repository;

import com.diabetes.health.entity.CommunityPost;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CommunityPostRepository extends JpaRepository<CommunityPost, Long> {

    Page<CommunityPost> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<CommunityPost> findAllByOrderByLikeCountDescCommentCountDescFavoriteCountDescCreatedAtDesc(Pageable pageable);

    @Modifying
    @Query("""
            UPDATE CommunityPost p
               SET p.likeCount =
                   CASE WHEN (p.likeCount + :delta) < 0 THEN 0 ELSE (p.likeCount + :delta) END
             WHERE p.id = :id
            """)
    void adjustLikeCount(@Param("id") Long id, @Param("delta") int delta);

    @Modifying
    @Query("""
            UPDATE CommunityPost p
               SET p.favoriteCount =
                   CASE WHEN (p.favoriteCount + :delta) < 0 THEN 0 ELSE (p.favoriteCount + :delta) END
             WHERE p.id = :id
            """)
    void adjustFavoriteCount(@Param("id") Long id, @Param("delta") int delta);

    @Modifying
    @Query("""
            UPDATE CommunityPost p
               SET p.commentCount =
                   CASE WHEN (p.commentCount + :delta) < 0 THEN 0 ELSE (p.commentCount + :delta) END
             WHERE p.id = :id
            """)
    void adjustCommentCount(@Param("id") Long id, @Param("delta") int delta);
}
