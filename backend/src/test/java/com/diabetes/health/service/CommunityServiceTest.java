package com.diabetes.health.service;

import com.diabetes.health.dto.CommunityDto;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CommunityServiceTest {

    @Mock
    private CommunityPostRepository communityPostRepository;

    @Mock
    private CommunityCommentRepository communityCommentRepository;

    @Mock
    private CommunityPostInteractionRepository communityPostInteractionRepository;

    @Mock
    private UserAccountRepository userAccountRepository;

    @Mock
    private UserHealthProfileRepository userHealthProfileRepository;

    @InjectMocks
    private CommunityService communityService;

    @Test
    void createPostUsesNicknameAsAuthorName() {
        CurrentUser user = new CurrentUser(1L, "13800138000", "PATIENT");
        CommunityDto.CreatePostRequest request = new CommunityDto.CreatePostRequest();
        request.setContent("今天控糖不错，大家晚餐都怎么搭配？");

        when(communityPostRepository.save(any(CommunityPost.class))).thenAnswer(invocation -> {
            CommunityPost saved = invocation.getArgument(0);
            saved.setId(10L);
            saved.setCreatedAt(Instant.parse("2026-04-13T12:00:00Z"));
            return saved;
        });
        when(userAccountRepository.findById(1L)).thenReturn(Optional.of(
                UserAccount.builder().id(1L).phone("13800138000").role(UserAccount.Role.PATIENT).build()
        ));
        when(userHealthProfileRepository.findByUserId(1L)).thenReturn(Optional.of(
                UserHealthProfile.builder().userId(1L).nickname("小笙").build()
        ));

        CommunityDto.PostResponse response = communityService.createPost(user, request);

        assertThat(response.getAuthorName()).isEqualTo("小笙");
        assertThat(response.getCommentCount()).isZero();
        assertThat(response.getLikeCount()).isZero();
        assertThat(response.getFavoriteCount()).isZero();
        assertThat(response.getLiked()).isFalse();
        assertThat(response.getFavorited()).isFalse();
    }

    @Test
    void listPostsReturnsPagedContent() {
        CommunityPost post = CommunityPost.builder()
                .id(11L)
                .userId(1L)
                .content("病友们有推荐的低 GI 早餐吗？")
                .commentCount(2)
                .likeCount(3)
                .favoriteCount(1)
                .createdAt(Instant.parse("2026-04-13T10:00:00Z"))
                .build();

        when(communityPostRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 20)))
                .thenReturn(new PageImpl<>(List.of(post), PageRequest.of(0, 20), 1));
        when(communityPostInteractionRepository.findByPostIdInAndUserId(eq(List.of(11L)), eq(1L)))
                .thenReturn(List.of(CommunityPostInteraction.builder()
                        .id(99L)
                        .postId(11L)
                        .userId(1L)
                        .liked(true)
                        .favorited(false)
                        .build()));
        when(userAccountRepository.findAllById(List.of(1L))).thenReturn(List.of(
                UserAccount.builder().id(1L).phone("13800138000").role(UserAccount.Role.PATIENT).build()
        ));
        when(userHealthProfileRepository.findAllByUserIdIn(List.of(1L))).thenReturn(List.of());

        CommunityDto.PageResult<CommunityDto.PostResponse> result = communityService.listPosts(
                new CurrentUser(1L, "13800138000", "PATIENT"),
                0,
                20
        );

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getContent()).contains("低 GI 早餐");
        assertThat(result.getContent().get(0).getLiked()).isTrue();
        assertThat(result.getContent().get(0).getFavorited()).isFalse();
    }

    @Test
    void toggleLikeReturnsUpdatedState() {
        CurrentUser user = new CurrentUser(2L, "13900001111", "PATIENT");
        CommunityPost post = CommunityPost.builder()
                .id(15L)
                .userId(1L)
                .content("晚饭后散步 20 分钟，感觉很有帮助。")
                .commentCount(1)
                .likeCount(0)
                .favoriteCount(0)
                .createdAt(Instant.parse("2026-04-13T10:00:00Z"))
                .build();

        when(communityPostRepository.findById(15L)).thenReturn(Optional.of(post));
        when(communityPostInteractionRepository.findByPostIdAndUserId(15L, 2L)).thenReturn(Optional.empty())
                .thenReturn(Optional.of(CommunityPostInteraction.builder()
                        .id(101L)
                        .postId(15L)
                        .userId(2L)
                        .liked(true)
                        .favorited(false)
                        .build()));
        when(userAccountRepository.findById(1L)).thenReturn(Optional.of(
                UserAccount.builder().id(1L).phone("13800138000").role(UserAccount.Role.PATIENT).build()
        ));
        when(userHealthProfileRepository.findByUserId(1L)).thenReturn(Optional.of(
                UserHealthProfile.builder().userId(1L).nickname("阿宁").build()
        ));
        when(communityPostInteractionRepository.save(any(CommunityPostInteraction.class))).thenAnswer(invocation -> {
            CommunityPostInteraction item = invocation.getArgument(0);
            item.setId(101L);
            return item;
        });
        doAnswer(invocation -> {
            post.setLikeCount(post.getLikeCount() + 1);
            return null;
        }).when(communityPostRepository).adjustLikeCount(15L, 1);

        CommunityDto.PostResponse response = communityService.toggleLike(user, 15L);

        assertThat(response.getLikeCount()).isEqualTo(1);
        assertThat(response.getLiked()).isTrue();
        assertThat(response.getAuthorName()).isEqualTo("阿宁");
    }

    @Test
    void listFavoritedPostsReturnsInteractionHistory() {
        CurrentUser user = new CurrentUser(1L, "13800138000", "PATIENT");
        CommunityPost post = CommunityPost.builder()
                .id(20L)
                .userId(2L)
                .content("收藏这条帖子，方便后面回看。")
                .commentCount(1)
                .likeCount(2)
                .favoriteCount(4)
                .createdAt(Instant.parse("2026-04-14T01:00:00Z"))
                .build();

        when(communityPostInteractionRepository.findByUserIdAndFavoritedTrueOrderByUpdatedAtDesc(
                1L,
                PageRequest.of(0, 20)
        )).thenReturn(new PageImpl<>(
                List.of(CommunityPostInteraction.builder()
                        .id(301L)
                        .postId(20L)
                        .userId(1L)
                        .liked(false)
                        .favorited(true)
                        .build()),
                PageRequest.of(0, 20),
                1
        ));
        when(communityPostRepository.findAllById(List.of(20L))).thenReturn(List.of(post));
        when(communityPostInteractionRepository.findByPostIdInAndUserId(List.of(20L), 1L)).thenReturn(
                List.of(CommunityPostInteraction.builder()
                        .id(301L)
                        .postId(20L)
                        .userId(1L)
                        .liked(false)
                        .favorited(true)
                        .build())
        );
        when(userAccountRepository.findAllById(List.of(2L))).thenReturn(List.of(
                UserAccount.builder().id(2L).phone("13900001111").role(UserAccount.Role.PATIENT).build()
        ));
        when(userHealthProfileRepository.findAllByUserIdIn(List.of(2L))).thenReturn(List.of());

        CommunityDto.PageResult<CommunityDto.PostResponse> result = communityService.listFavoritedPosts(user, 0, 20);

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getFavorited()).isTrue();
        assertThat(result.getContent().get(0).getId()).isEqualTo(20L);
    }
}
