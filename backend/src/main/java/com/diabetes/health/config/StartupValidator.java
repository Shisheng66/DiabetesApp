package com.diabetes.health.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * 配置验证器 - 在应用启动时验证关键配置
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StartupValidator {

    private static final String UNSAFE_DEFAULT_JWT_SECRET =
            "dev-only-secret-please-change-in-prod-32chars";

    private final JwtProperties jwtProperties;
    private final AppProperties appProperties;
    private final AuthVerificationProperties authVerificationProperties;
    private final SmsProperties smsProperties;
    private final StringRedisTemplate redisTemplate;
    private final Environment environment;

    @PostConstruct
    public void validate() {
        log.info("开始验证启动配置...");
        
        // 验证 JWT 配置
        validateJwtConfig();
        
        // 验证应用配置
        validateAppConfig();

        // 验证认证配置
        validateAuthConfig();

        // 生产环境验证外部依赖
        validateProductionDependencies();
        
        log.info("配置验证通过！");
    }

    private void validateJwtConfig() {
        if (jwtProperties.getSecret() == null || jwtProperties.getSecret().length() < 32) {
            throw new IllegalStateException(
                "JWT secret 配置错误：必须至少 32 个字符。当前长度：" + 
                (jwtProperties.getSecret() != null ? jwtProperties.getSecret().length() : 0)
            );
        }

        if (UNSAFE_DEFAULT_JWT_SECRET.equals(jwtProperties.getSecret())) {
            throw new IllegalStateException("JWT secret 使用了默认不安全值，请通过环境变量 JWT_SECRET 设置");
        }
        
        if (jwtProperties.getExpirationSeconds() == null || jwtProperties.getExpirationSeconds() <= 0) {
            throw new IllegalStateException("JWT expiration-seconds 配置错误：必须大于 0");
        }
        
        log.debug("✓ JWT 配置验证通过");
    }

    private void validateAppConfig() {
        if (appProperties.getName() == null || appProperties.getName().trim().isEmpty()) {
            throw new IllegalStateException("应用名称不能为空");
        }
        
        if (appProperties.getCors() == null) {
            throw new IllegalStateException("CORS 配置不能为空");
        }

        boolean prod = isProd();
        String allowedOrigins = appProperties.getCors().getAllowedOrigins();
        if (prod && (allowedOrigins == null || allowedOrigins.isBlank() || allowedOrigins.contains("*"))) {
            throw new IllegalStateException("生产环境必须通过 APP_CORS_ALLOWED_ORIGINS 配置明确的前端域名，不能使用通配符");
        }
        
        log.debug("✓ 应用配置验证通过");
    }

    private void validateAuthConfig() {
        if (isProd() && authVerificationProperties.isExposeDebugSmsCode()) {
            throw new IllegalStateException("生产环境禁止开启 expose-debug-sms-code");
        }

        log.debug("✓ 认证配置验证通过");
    }

    private void validateProductionDependencies() {
        if (!isProd()) {
            return;
        }

        try {
            String pong = redisTemplate.getConnectionFactory().getConnection().ping();
            if (pong == null || pong.isBlank()) {
                throw new IllegalStateException("Redis ping 没有返回有效结果");
            }
        } catch (Exception ex) {
            throw new IllegalStateException("生产环境必须连接可用 Redis，用于验证码与登出黑名单", ex);
        }

        if (!"http".equalsIgnoreCase(smsProperties.getProvider())) {
            throw new IllegalStateException("生产环境短信 provider 目前仅支持 http");
        }
        if (smsProperties.getEndpoint() == null || smsProperties.getEndpoint().isBlank()) {
            throw new IllegalStateException("生产环境必须配置 APP_SMS_ENDPOINT");
        }
        if (smsProperties.getToken() == null || smsProperties.getToken().isBlank()) {
            throw new IllegalStateException("生产环境必须配置 APP_SMS_TOKEN");
        }
        if (smsProperties.getEndpoint().contains("example.com")
                || "replace-with-provider-token".equalsIgnoreCase(smsProperties.getToken())) {
            throw new IllegalStateException("生产环境短信配置仍是占位值，请替换为真实短信平台 APP_SMS_ENDPOINT / APP_SMS_TOKEN");
        }

        log.debug("✓ 生产外部依赖验证通过");
    }

    private boolean isProd() {
        return Arrays.asList(environment.getActiveProfiles()).contains("prod");
    }
}
