package com.diabetes.health.controller;

import com.diabetes.health.dto.CommunityDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.CommunityService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/community")
@RequiredArgsConstructor
public class CommunityController {

    private final CommunityService communityService;

    @PostMapping("/posts")
    public CommunityDto.PostResponse createPost(
            @AuthenticationPrincipal CurrentUser user,
            @RequestBody CommunityDto.CreatePostRequest request
    ) {
        return communityService.createPost(user, request);
    }

    @GetMapping("/posts")
    public CommunityDto.PageResult<CommunityDto.PostResponse> listPosts(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return communityService.listPosts(user, page, size);
    }

    @GetMapping("/hot-posts")
    public CommunityDto.PageResult<CommunityDto.PostResponse> listHotPosts(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return communityService.listHotPosts(user, page, size);
    }

    @GetMapping("/posts/liked")
    public CommunityDto.PageResult<CommunityDto.PostResponse> listLikedPosts(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return communityService.listLikedPosts(user, page, size);
    }

    @GetMapping("/posts/favorited")
    public CommunityDto.PageResult<CommunityDto.PostResponse> listFavoritedPosts(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return communityService.listFavoritedPosts(user, page, size);
    }

    @GetMapping("/posts/{postId}")
    public CommunityDto.PostResponse getPost(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long postId
    ) {
        return communityService.getPost(user, postId);
    }

    @PostMapping("/posts/{postId}/comments")
    public CommunityDto.CommentResponse createComment(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long postId,
            @RequestBody CommunityDto.CreateCommentRequest request
    ) {
        return communityService.createComment(user, postId, request);
    }

    @GetMapping("/posts/{postId}/comments")
    public CommunityDto.PageResult<CommunityDto.CommentResponse> listComments(
            @PathVariable Long postId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size
    ) {
        return communityService.listComments(postId, page, size);
    }

    @PostMapping("/posts/{postId}/like")
    public CommunityDto.PostResponse toggleLike(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long postId
    ) {
        return communityService.toggleLike(user, postId);
    }

    @PostMapping("/posts/{postId}/favorite")
    public CommunityDto.PostResponse toggleFavorite(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long postId
    ) {
        return communityService.toggleFavorite(user, postId);
    }
}
