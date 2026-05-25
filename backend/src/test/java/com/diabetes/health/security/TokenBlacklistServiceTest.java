package com.diabetes.health.security;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TokenBlacklistServiceTest {

    @Mock private StringRedisTemplate redisTemplate;
    @Mock private ValueOperations<String, String> valueOps;
    @InjectMocks private TokenBlacklistService tokenBlacklistService;

    @Test
    void isRevoked_shouldReturnFalseForNonRevokedToken() {
        when(redisTemplate.hasKey("jwt:blacklist:token123")).thenReturn(false);
        assertThat(tokenBlacklistService.isRevoked("token123")).isFalse();
    }

    @Test
    void isRevoked_shouldReturnTrueForRevokedToken() {
        when(redisTemplate.hasKey("jwt:blacklist:token123")).thenReturn(true);
        assertThat(tokenBlacklistService.isRevoked("token123")).isTrue();
    }

    @Test
    void revoke_shouldFallbackToMemoryWhenRedisFails() {
        when(redisTemplate.opsForValue()).thenReturn(valueOps);
        doThrow(new org.springframework.data.redis.RedisConnectionFailureException("fail"))
            .when(valueOps).set(anyString(), anyString(), any(Duration.class));
        doThrow(new org.springframework.data.redis.RedisConnectionFailureException("fail"))
            .when(redisTemplate).hasKey("jwt:blacklist:token123");

        // Should not throw
        tokenBlacklistService.revoke("token123", java.time.Instant.now().plusSeconds(3600));

        // Should be in fallback map
        assertThat(tokenBlacklistService.isRevoked("token123")).isTrue();
    }
}
