package com.diabetes.health.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
@org.springframework.context.annotation.Profile("!test")
@Slf4j
@RequiredArgsConstructor
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private static final long WINDOW_MILLIS = Duration.ofMinutes(1).toMillis();
    private static final int AUTH_REQUEST_LIMIT = 10;
    private static final int SMS_REQUEST_LIMIT = 3;
    private static final String KEY_PREFIX = "rate:auth:";

    private final StringRedisTemplate redisTemplate;
    private final Cache<String, Deque<Long>> requestBuckets = Caffeine.newBuilder()
            .maximumSize(50_000)
            .expireAfterAccess(2, TimeUnit.MINUTES)
            .build();
    private final AtomicBoolean fallbackLogged = new AtomicBoolean(false);

    @Value("${spring.profiles.active:}")
    private String activeProfiles;

    @Value("${app.security.trusted-proxy-addresses:127.0.0.1,::1}")
    private String trustedProxyAddresses;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        if (uri == null) {
            return true;
        }
        if ("/api/auth/logout".equals(uri)) {
            return true;
        }
        return !uri.startsWith("/api/auth/");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String key = buildBucketKey(request);
        int limit = request.getRequestURI().startsWith("/api/auth/sms/") ? SMS_REQUEST_LIMIT : AUTH_REQUEST_LIMIT;
        if (!tryConsume(key, limit)) {
            response.setStatus(429);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write("{\"message\":\"请求过于频繁，请稍后再试\",\"status\":429}");
            return;
        }
        filterChain.doFilter(request, response);
    }

    private boolean tryConsume(String key, int limit) {
        Boolean redisResult = tryConsumeRedis(key, limit);
        if (redisResult != null) {
            return redisResult;
        }
        return tryConsumeLocal(key, limit);
    }

    private Boolean tryConsumeRedis(String key, int limit) {
        try {
            String redisKey = KEY_PREFIX + sha256(key);
            Long count = redisTemplate.opsForValue().increment(redisKey);
            if (count != null && count == 1L) {
                redisTemplate.expire(redisKey, Duration.ofMillis(WINDOW_MILLIS));
            }
            return count != null && count <= limit;
        } catch (DataAccessException ex) {
            failIfProdRedisUnavailable(ex);
            logFallbackOnce(ex);
            return null;
        }
    }

    private boolean tryConsumeLocal(String key, int limit) {
        long now = System.currentTimeMillis();
        Deque<Long> timestamps = requestBuckets.get(key, unused -> new ArrayDeque<>());
        synchronized (timestamps) {
            while (!timestamps.isEmpty() && now - timestamps.peekFirst() > WINDOW_MILLIS) {
                timestamps.pollFirst();
            }
            if (timestamps.size() >= limit) {
                return false;
            }
            timestamps.addLast(now);
            return true;
        }
    }

    private String buildBucketKey(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        String remoteAddr = request.getRemoteAddr();
        String ip = forwardedFor != null && !forwardedFor.isBlank() && isTrustedProxy(remoteAddr)
                ? forwardedFor.split(",")[0].trim()
                : remoteAddr;
        return ip + ":" + request.getRequestURI();
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder builder = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) {
                builder.append(String.format("%02x", b));
            }
            return builder.toString();
        } catch (Exception ignored) {
            return Integer.toHexString(value.hashCode());
        }
    }

    private void logFallbackOnce(Exception ex) {
        if (fallbackLogged.compareAndSet(false, true)) {
            log.warn("Redis 不可用，认证限流暂时退回到内存存储。生产环境请确保 Redis 已启动。原因: {}", ex.getMessage());
        }
    }

    private void failIfProdRedisUnavailable(Exception ex) {
        if (isProd()) {
            throw new IllegalStateException("生产认证限流依赖 Redis，但当前 Redis 不可用", ex);
        }
    }

    private boolean isProd() {
        return activeProfiles != null && Arrays.stream(activeProfiles.split(","))
                .map(String::trim)
                .anyMatch("prod"::equalsIgnoreCase);
    }

    private boolean isTrustedProxy(String remoteAddr) {
        if (remoteAddr == null || remoteAddr.isBlank()) {
            return false;
        }
        return Arrays.stream(trustedProxyAddresses.split(","))
                .map(String::trim)
                .anyMatch(remoteAddr::equals);
    }
}
