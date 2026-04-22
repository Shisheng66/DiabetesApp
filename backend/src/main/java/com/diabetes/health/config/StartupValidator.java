package com.diabetes.health.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
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
        
        log.debug("✓ 应用配置验证通过");
    }

    private void validateAuthConfig() {
        boolean prod = Arrays.asList(environment.getActiveProfiles()).contains("prod");
        if (prod && authVerificationProperties.isExposeDebugSmsCode()) {
            throw new IllegalStateException("生产环境禁止开启 expose-debug-sms-code");
        }

        log.debug("✓ 认证配置验证通过");
    }
}
