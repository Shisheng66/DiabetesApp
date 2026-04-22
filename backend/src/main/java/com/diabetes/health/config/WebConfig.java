package com.diabetes.health.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CORS：允许 Flutter / Web 前端跨域访问。
 */
@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final AppProperties appProperties;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        AppProperties.CorsConfig cors = appProperties.getCors();
        registry.addMapping("/api/**")
                .allowedOriginPatterns(splitCsv(cors.getAllowedOrigins()))
                .allowedMethods(splitCsv(cors.getAllowedMethods()))
                .allowedHeaders(splitCsv(cors.getAllowedHeaders()))
                .allowCredentials(Boolean.TRUE.equals(cors.getAllowCredentials()))
                .maxAge(cors.getMaxAge());
    }

    private String[] splitCsv(String value) {
        if (value == null || value.isBlank()) {
            return new String[]{"*"};
        }
        return java.util.Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(item -> !item.isEmpty())
                .toArray(String[]::new);
    }
}
