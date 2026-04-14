package com.diabetes.health.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 工具类 — 已升级到 jjwt 0.12.x API。
 *
 * pom.xml 依赖需同步升级：
 *   <version>0.12.6</version>  （jjwt-api / jjwt-impl / jjwt-jackson）
 */
@Component
public class JwtUtil {

    private final SecretKey key;
    private final long expirationMs;

    public JwtUtil(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-seconds:604800}") long expirationSeconds
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationSeconds * 1000L;
    }

    public String generate(Long userId, String phone, String role) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);
        // jjwt 0.12.x：使用 subject() 替代 claim("sub", ...)
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("phone", phone)
                .claim("role", role)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        // jjwt 0.12.x：使用 verifyWith().build().parseSignedClaims()
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long getUserId(String token) {
        String sub = parse(token).getSubject();
        return sub != null ? Long.parseLong(sub) : null;
    }

    public boolean validate(String token) {
        try {
            parse(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
