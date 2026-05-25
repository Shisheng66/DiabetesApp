package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(
        name = "community_post_interaction",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_community_post_interaction_post_user", columnNames = {"post_id", "user_id"})
        },
        indexes = {
                @Index(name = "idx_community_post_interaction_post_user", columnList = "post_id, user_id"),
                @Index(name = "idx_community_post_interaction_user_updated", columnList = "user_id, updated_at")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommunityPostInteraction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "liked", nullable = false)
    @Builder.Default
    private Boolean liked = false;

    @Column(name = "favorited", nullable = false)
    @Builder.Default
    private Boolean favorited = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
