package com.diabetes.health.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.concurrent.TimeUnit;

@Component
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private static final long WINDOW_MILLIS = Duration.ofMinutes(1).toMillis();
    private static final int AUTH_REQUEST_LIMIT = 10;
    private static final int SMS_REQUEST_LIMIT = 3;

    private final Cache<String, Deque<Long>> requestBuckets = Caffeine.newBuilder()
            .maximumSize(50_000)
            .expireAfterAccess(2, TimeUnit.MINUTES)
            .build();

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

    private boolean isTrustedProxy(String remoteAddr) {
        if (remoteAddr == null || remoteAddr.isBlank()) {
            return false;
        }
        return "127.0.0.1".equals(remoteAddr)
                || "0:0:0:0:0:0:0:1".equals(remoteAddr)
                || "::1".equals(remoteAddr)
                || remoteAddr.startsWith("10.")
                || remoteAddr.startsWith("192.168.")
                || remoteAddr.matches("^172\\.(1[6-9]|2\\d|3[0-1])\\..*");
    }
}
