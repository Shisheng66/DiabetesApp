package com.diabetes.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.Instant;
import java.util.List;

public class CommunityDto {

    @Data
    public static class CreatePostRequest {
        @NotBlank(message = "帖子内容不能为空")
        @Size(max = 1200, message = "帖子内容不能超过1200字")
        private String content;
    }

    @Data
    public static class CreateCommentRequest {
        @NotBlank(message = "评论内容不能为空")
        @Size(max = 800, message = "评论内容不能超过800字")
        private String content;
    }

    @Data
    public static class PostResponse {
        private Long id;
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
        private String authorName;
        private String authorRole;
        private String authorAvatarUrl;
        private String content;
        private Instant createdAt;
    }

    @Data
    @EqualsAndHashCode(callSuper = true)
    public static class AdminPostResponse extends PostResponse {
        private Long userId;
        private String authorRoleRaw;
    }

    @Data
    @EqualsAndHashCode(callSuper = true)
    public static class AdminCommentResponse extends CommentResponse {
        private Long userId;
        private String authorRoleRaw;
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
