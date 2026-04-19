package com.diabetes.health.dto;

import lombok.Data;

import java.time.Instant;
import java.util.List;

public class CommunityDto {

    @Data
    public static class CreatePostRequest {
        private String content;
    }

    @Data
    public static class CreateCommentRequest {
        private String content;
    }

    @Data
    public static class PostResponse {
        private Long id;
        private Long userId;
        private String authorName;
        private String authorRole;
        private String authorAvatarUrl;
        private String content;
        private Integer commentCount;
        private Integer likeCount;
        private Integer favoriteCount;
        private Boolean liked;
        private Boolean favorited;
        private Instant createdAt;
    }

    @Data
    public static class CommentResponse {
        private Long id;
        private Long postId;
        private Long userId;
        private String authorName;
        private String authorRole;
        private String authorAvatarUrl;
        private String content;
        private Instant createdAt;
    }

    @Data
    public static class PageResult<T> {
        private List<T> content;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;
    }
}
