package com.diabetes.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * JWT 配置属性
 */
@Data
@Component
@ConfigurationProperties(prefix = "app.jwt")
public class JwtProperties {

    /**
     * JWT 密钥（至少 32 字符）
     */
    private String secret;

    /**
     * JWT 过期时间（秒）
     */
    private Long expirationSeconds;

    /**
     * JWT 令牌前缀
     */
    private String tokenPrefix = "Bearer ";

    /**
     * JWT header 名称
     */
    private String header = "Authorization";
}
