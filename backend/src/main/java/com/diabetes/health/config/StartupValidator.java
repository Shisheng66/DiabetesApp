package com.diabetes.health.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 配置验证器 - 在应用启动时验证关键配置
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StartupValidator {

    private final JwtProperties jwtProperties;
    private final AppProperties appProperties;

    @PostConstruct
    public void validate() {
        log.info("开始验证启动配置...");
        
        // 验证 JWT 配置
        validateJwtConfig();
        
        // 验证应用配置
        validateAppConfig();
        
        log.info("配置验证通过！");
    }

    private void validateJwtConfig() {
        if (jwtProperties.getSecret() == null || jwtProperties.getSecret().length() < 32) {
            throw new IllegalStateException(
                "JWT secret 配置错误：必须至少 32 个字符。当前长度：" + 
                (jwtProperties.getSecret() != null ? jwtProperties.getSecret().length() : 0)
            );
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
}
