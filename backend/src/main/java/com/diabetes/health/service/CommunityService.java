package com.diabetes.health.service;

import com.diabetes.health.dto.CommunityDto;
import com.diabetes.health.entity.CommunityComment;
import com.diabetes.health.entity.CommunityPost;
import com.diabetes.health.entity.CommunityPostInteraction;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.CommunityCommentRepository;
import com.diabetes.health.repository.CommunityPostInteractionRepository;
import com.diabetes.health.repository.CommunityPostRepository;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class CommunityService {

    private final CommunityPostRepository communityPostRepository;
    private final CommunityCommentRepository communityCommentRepository;
    private final CommunityPostInteractionRepository communityPostInteractionRepository;
    private final UserAccountRepository userAccountRepository;
    private final UserHealthProfileRepository userHealthProfileRepository;

    @Transactional
    public CommunityDto.PostResponse createPost(CurrentUser user, CommunityDto.CreatePostRequest request) {
        String content = normalizeContent(request.getContent(), 1200, "帖子内容不能为空");
        CommunityPost saved = communityPostRepository.save(CommunityPost.builder()
                .userId(user.getId())
                .content(content)
                .build());
        return toPostResponse(saved, loadAuthor(user.getId()), InteractionState.none());
    }

    public CommunityDto.PageResult<CommunityDto.PostResponse> listPosts(CurrentUser user, int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 50);
        Page<CommunityPost> postPage = communityPostRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(safePage, safeSize));

        Map<Long, AuthorSummary> authors = loadAuthors(postPage.getContent().stream().map(CommunityPost::getUserId).toList());
        Map<Long, InteractionState> interactions = loadInteractionStates(
                postPage.getContent().stream().map(CommunityPost::getId).toList(),
                user == null ? null : user.getId()
        );

        CommunityDto.PageResult<CommunityDto.PostResponse> result = new CommunityDto.PageResult<>();
        result.setContent(postPage.getContent().stream()
                .map(post -> toPostResponse(
                        post,
                        authors.get(post.getUserId()),
                        interactions.getOrDefault(post.getId(), InteractionState.none())
                ))
                .toList());
        result.setPage(postPage.getNumber());
        result.setSize(postPage.getSize());
        result.setTotalElements(postPage.getTotalElements());
        result.setTotalPages(postPage.getTotalPages());
        return result;
    }

    public CommunityDto.PageResult<CommunityDto.PostResponse> listHotPosts(CurrentUser user, int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 50);
        Page<CommunityPost> postPage = communityPostRepository
                .findAllByOrderByLikeCountDescCommentCountDescFavoriteCountDescCreatedAtDesc(
                        PageRequest.of(safePage, safeSize)
                );

        Map<Long, AuthorSummary> authors = loadAuthors(
                postPage.getContent().stream().map(CommunityPost::getUserId).toList()
        );
        Map<Long, InteractionState> interactions = loadInteractionStates(
                postPage.getContent().stream().map(CommunityPost::getId).toList(),
                user == null ? null : user.getId()
        );

        CommunityDto.PageResult<CommunityDto.PostResponse> result = new CommunityDto.PageResult<>();
        result.setContent(postPage.getContent().stream()
                .map(post -> toPostResponse(
                        post,
                        authors.get(post.getUserId()),
                        interactions.getOrDefault(post.getId(), InteractionState.none())
                ))
                .toList());
        result.setPage(postPage.getNumber());
        result.setSize(postPage.getSize());
        result.setTotalElements(postPage.getTotalElements());
        result.setTotalPages(postPage.getTotalPages());
        return result;
    }

    public CommunityDto.PageResult<CommunityDto.PostResponse> listLikedPosts(CurrentUser user, int page, int size) {
        return listInteractedPosts(user, page, size, true);
    }

    public CommunityDto.PageResult<CommunityDto.PostResponse> listFavoritedPosts(CurrentUser user, int page, int size) {
        return listInteractedPosts(user, page, size, false);
    }

    public CommunityDto.PostResponse getPost(CurrentUser user, Long postId) {
        CommunityPost post = requirePost(postId);
        return toPostResponse(
                post,
                loadAuthor(post.getUserId()),
                loadInteractionState(postId, user == null ? null : user.getId())
        );
    }

    @Transactional
    public CommunityDto.CommentResponse createComment(CurrentUser user, Long postId, CommunityDto.CreateCommentRequest request) {
        CommunityPost post = requirePost(postId);
        String content = normalizeContent(request.getContent(), 800, "评论内容不能为空");

        CommunityComment saved = communityCommentRepository.save(CommunityComment.builder()
                .postId(postId)
                .userId(user.getId())
                .content(content)
                .build());

        post.setCommentCount(Math.toIntExact(communityCommentRepository.countByPostId(postId)));
        communityPostRepository.save(post);

        return toCommentResponse(saved, loadAuthor(user.getId()));
    }

    public CommunityDto.PageResult<CommunityDto.CommentResponse> listComments(Long postId, int page, int size) {
        if (!communityPostRepository.existsById(postId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "帖子不存在");
        }
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);

        Page<CommunityComment> commentPage = communityCommentRepository.findByPostIdOrderByCreatedAtAsc(postId, PageRequest.of(safePage, safeSize));

        Map<Long, AuthorSummary> authors = loadAuthors(commentPage.getContent().stream().map(CommunityComment::getUserId).toList());

        CommunityDto.PageResult<CommunityDto.CommentResponse> result = new CommunityDto.PageResult<>();
        result.setContent(commentPage.getContent().stream()
                .map(comment -> toCommentResponse(comment, authors.get(comment.getUserId())))
                .toList());
        result.setPage(commentPage.getNumber());
        result.setSize(commentPage.getSize());
        result.setTotalElements(commentPage.getTotalElements());
        result.setTotalPages(commentPage.getTotalPages());
        return result;
    }

    @Transactional
    public CommunityDto.PostResponse toggleLike(CurrentUser user, Long postId) {
        CommunityPost post = requirePost(postId);
        CommunityPostInteraction interaction = communityPostInteractionRepository.findByPostIdAndUserId(postId, user.getId())
                .orElseGet(() -> CommunityPostInteraction.builder()
                        .postId(postId)
                        .userId(user.getId())
                        .build());

        interaction.setLiked(!Boolean.TRUE.equals(interaction.getLiked()));
        persistOrDeleteInteraction(interaction);
        syncCounters(post);
        return getPost(user, postId);
    }

    @Transactional
    public CommunityDto.PostResponse toggleFavorite(CurrentUser user, Long postId) {
        CommunityPost post = requirePost(postId);
        CommunityPostInteraction interaction = communityPostInteractionRepository.findByPostIdAndUserId(postId, user.getId())
                .orElseGet(() -> CommunityPostInteraction.builder()
                        .postId(postId)
                        .userId(user.getId())
                        .build());

        interaction.setFavorited(!Boolean.TRUE.equals(interaction.getFavorited()));
        persistOrDeleteInteraction(interaction);
        syncCounters(post);
        return getPost(user, postId);
    }

    private String normalizeContent(String content, int maxLength, String emptyMessage) {
        String normalized = content == null ? "" : content.trim();
        if (normalized.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, emptyMessage);
        }
        if (normalized.length() > maxLength) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "内容长度不能超过 " + maxLength + " 字");
        }
        return normalized;
    }

    private CommunityDto.PageResult<CommunityDto.PostResponse> listInteractedPosts(
            CurrentUser user,
            int page,
            int size,
            boolean liked
    ) {
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "请先登录后再查看互动记录");
        }

        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 50);
        Page<CommunityPostInteraction> interactionPage = liked
                ? communityPostInteractionRepository.findByUserIdAndLikedTrueOrderByUpdatedAtDesc(
                        user.getId(),
                        PageRequest.of(safePage, safeSize)
                )
                : communityPostInteractionRepository.findByUserIdAndFavoritedTrueOrderByUpdatedAtDesc(
                        user.getId(),
                        PageRequest.of(safePage, safeSize)
                );

        List<Long> postIds = interactionPage.getContent().stream()
                .map(CommunityPostInteraction::getPostId)
                .toList();
        Map<Long, CommunityPost> postsById = new HashMap<>();
        for (CommunityPost post : communityPostRepository.findAllById(postIds)) {
            postsById.put(post.getId(), post);
        }

        List<CommunityPost> orderedPosts = postIds.stream()
                .map(postsById::get)
                .filter(Objects::nonNull)
                .toList();
        Map<Long, AuthorSummary> authors = loadAuthors(
                orderedPosts.stream().map(CommunityPost::getUserId).toList()
        );
        Map<Long, InteractionState> interactions = loadInteractionStates(postIds, user.getId());

        CommunityDto.PageResult<CommunityDto.PostResponse> result = new CommunityDto.PageResult<>();
        result.setContent(orderedPosts.stream()
                .map(post -> toPostResponse(
                        post,
                        authors.get(post.getUserId()),
                        interactions.getOrDefault(post.getId(), InteractionState.none())
                ))
                .toList());
        result.setPage(interactionPage.getNumber());
        result.setSize(interactionPage.getSize());
        result.setTotalElements(interactionPage.getTotalElements());
        result.setTotalPages(interactionPage.getTotalPages());
        return result;
    }

    private CommunityPost requirePost(Long postId) {
        return communityPostRepository.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "帖子不存在"));
    }

    private void persistOrDeleteInteraction(CommunityPostInteraction interaction) {
        boolean liked = Boolean.TRUE.equals(interaction.getLiked());
        boolean favorited = Boolean.TRUE.equals(interaction.getFavorited());
        if (!liked && !favorited) {
            if (interaction.getId() != null) {
                communityPostInteractionRepository.delete(interaction);
            }
            return;
        }
        communityPostInteractionRepository.save(interaction);
    }

    private void syncCounters(CommunityPost post) {
        post.setLikeCount(Math.toIntExact(communityPostInteractionRepository.countByPostIdAndLikedTrue(post.getId())));
        post.setFavoriteCount(Math.toIntExact(communityPostInteractionRepository.countByPostIdAndFavoritedTrue(post.getId())));
        communityPostRepository.save(post);
    }

    private Map<Long, AuthorSummary> loadAuthors(List<Long> userIds) {
        Map<Long, AuthorSummary> result = new HashMap<>();
        if (userIds.isEmpty()) {
            return result;
        }
        for (Long userId : userIds) {
            result.putIfAbsent(userId, loadAuthor(userId));
        }
        return result;
    }

    private Map<Long, InteractionState> loadInteractionStates(List<Long> postIds, Long userId) {
        Map<Long, InteractionState> result = new HashMap<>();
        if (userId == null || postIds.isEmpty()) {
            return result;
        }
        for (CommunityPostInteraction item : communityPostInteractionRepository.findByPostIdInAndUserId(postIds, userId)) {
            result.put(item.getPostId(), new InteractionState(Boolean.TRUE.equals(item.getLiked()), Boolean.TRUE.equals(item.getFavorited())));
        }
        return result;
    }

    private InteractionState loadInteractionState(Long postId, Long userId) {
        if (userId == null) {
            return InteractionState.none();
        }
        return communityPostInteractionRepository.findByPostIdAndUserId(postId, userId)
                .map(item -> new InteractionState(Boolean.TRUE.equals(item.getLiked()), Boolean.TRUE.equals(item.getFavorited())))
                .orElseGet(InteractionState::none);
    }

    private AuthorSummary loadAuthor(Long userId) {
        UserAccount account = userAccountRepository.findById(userId).orElse(null);
        UserHealthProfile profile = userHealthProfileRepository.findByUserId(userId).orElse(null);

        String authorName = "病友";
        if (profile != null && profile.getNickname() != null && !profile.getNickname().isBlank()) {
            authorName = profile.getNickname();
        } else if (account != null && account.getPhone() != null && account.getPhone().length() >= 4) {
            String phone = account.getPhone();
            authorName = "病友" + phone.substring(phone.length() - 4);
        }

        String authorRole = account == null || account.getRole() == null ? "PATIENT" : account.getRole().name();
        String avatarUrl = profile == null ? null : profile.getAvatarUrl();
        return new AuthorSummary(authorName, authorRole, avatarUrl);
    }

    private CommunityDto.PostResponse toPostResponse(CommunityPost post, AuthorSummary author, InteractionState interaction) {
        CommunityDto.PostResponse response = new CommunityDto.PostResponse();
        response.setId(post.getId());
        response.setUserId(post.getUserId());
        response.setAuthorName(author == null ? "病友" : author.name());
        response.setAuthorRole(author == null ? "PATIENT" : author.role());
        response.setAuthorAvatarUrl(author == null ? null : author.avatarUrl());
        response.setContent(post.getContent());
        response.setCommentCount(Objects.requireNonNullElse(post.getCommentCount(), 0));
        response.setLikeCount(Objects.requireNonNullElse(post.getLikeCount(), 0));
        response.setFavoriteCount(Objects.requireNonNullElse(post.getFavoriteCount(), 0));
        response.setLiked(interaction.liked());
        response.setFavorited(interaction.favorited());
        response.setCreatedAt(post.getCreatedAt());
        return response;
    }

    private CommunityDto.CommentResponse toCommentResponse(CommunityComment comment, AuthorSummary author) {
        CommunityDto.CommentResponse response = new CommunityDto.CommentResponse();
        response.setId(comment.getId());
        response.setPostId(comment.getPostId());
        response.setUserId(comment.getUserId());
        response.setAuthorName(author == null ? "病友" : author.name());
        response.setAuthorRole(author == null ? "PATIENT" : author.role());
        response.setAuthorAvatarUrl(author == null ? null : author.avatarUrl());
        response.setContent(comment.getContent());
        response.setCreatedAt(comment.getCreatedAt());
        return response;
    }

    private record AuthorSummary(String name, String role, String avatarUrl) {}

    private record InteractionState(boolean liked, boolean favorited) {
        private static InteractionState none() {
            return new InteractionState(false, false);
        }
    }
}
