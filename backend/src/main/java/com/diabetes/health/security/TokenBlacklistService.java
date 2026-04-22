package com.diabetes.health.security;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
@Slf4j
@RequiredArgsConstructor
public class TokenBlacklistService {

    private static final String KEY_PREFIX = "jwt:blacklist:";

    private final StringRedisTemplate redisTemplate;

    private final Map<String, Instant> fallbackRevokedTokens = new ConcurrentHashMap<>();
    private final AtomicBoolean fallbackLogged = new AtomicBoolean(false);

    public void revoke(String token, Instant expiresAt) {
        if (token == null || token.isBlank() || expiresAt == null) {
            return;
        }
        Duration ttl = Duration.between(Instant.now(), expiresAt);
        if (ttl.isNegative() || ttl.isZero()) {
            return;
        }

        if (writeToRedis(token, ttl)) {
            fallbackRevokedTokens.remove(token);
            return;
        }

        fallbackRevokedTokens.put(token, expiresAt);
        purgeExpired();
    }

    public boolean isRevoked(String token) {
        if (token == null || token.isBlank()) {
            return false;
        }
        purgeExpired();

        Boolean redisResult = readFromRedis(token);
        if (redisResult != null) {
            if (!redisResult) {
                fallbackRevokedTokens.remove(token);
            }
            return redisResult;
        }

        Instant expiresAt = fallbackRevokedTokens.get(token);
        return expiresAt != null && expiresAt.isAfter(Instant.now());
    }

    private boolean writeToRedis(String token, Duration ttl) {
        try {
            redisTemplate.opsForValue().set(KEY_PREFIX + token, "1", ttl);
            return true;
        } catch (RedisConnectionFailureException ex) {
            logFallbackOnce(ex);
            return false;
        }
    }

    private Boolean readFromRedis(String token) {
        try {
            return Boolean.TRUE.equals(redisTemplate.hasKey(KEY_PREFIX + token));
        } catch (RedisConnectionFailureException ex) {
            logFallbackOnce(ex);
            return null;
        }
    }

    private void purgeExpired() {
        Instant now = Instant.now();
        fallbackRevokedTokens.entrySet().removeIf(entry -> !entry.getValue().isAfter(now));
    }

    private void logFallbackOnce(Exception ex) {
        if (fallbackLogged.compareAndSet(false, true)) {
            log.warn("Redis 不可用，Token 黑名单暂时退回到内存存储。生产环境请确保 Redis 已启动。原因: {}", ex.getMessage());
        }
    }
}
