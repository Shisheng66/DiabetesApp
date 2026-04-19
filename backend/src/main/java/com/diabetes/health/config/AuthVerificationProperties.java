package com.diabetes.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "app.auth")
public class AuthVerificationProperties {

    private long captchaExpireSeconds = 180;

    private long smsExpireSeconds = 300;

    private long smsCooldownSeconds = 60;

    private boolean exposeDebugSmsCode = true;
}
