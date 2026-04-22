package com.diabetes.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 应用配置属性
 */
@Data
@Component
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    /**
     * 应用名称
     */
    private String name = "糖尿病健康管理系统";

    /**
     * 应用版本
     */
    private String version = "1.0.0";

    /**
     * CORS 配置
     */
    private CorsConfig cors = new CorsConfig();

    @Data
    public static class CorsConfig {
        /**
         * 允许的源
         */
        private String allowedOrigins = "*";

        /**
         * 允许的方法
         */
        private String allowedMethods = "GET,POST,PUT,DELETE,OPTIONS";

        /**
         * 允许的 headers
         */
        private String allowedHeaders = "*";

        /**
         * 是否允许凭证
         */
        private Boolean allowCredentials = false;

        /**
         * 预检请求缓存时间
         */
        private Long maxAge = 3600L;
    }
}
