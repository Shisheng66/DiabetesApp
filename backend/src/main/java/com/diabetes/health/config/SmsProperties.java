package com.diabetes.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "app.sms")
public class SmsProperties {

    /**
     * prod uses the HTTP provider. dev/test keep using MockSmsSender.
     */
    private String provider = "http";

    private String endpoint;

    private String token;

    private String signature;

    private String templateId;

    private Integer connectTimeoutSeconds = 3;

    private Integer requestTimeoutSeconds = 5;
}
