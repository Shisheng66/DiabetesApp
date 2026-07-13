package com.diabetes.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "app.payment")
public class PaymentProperties {

    /** Shared secret used by the payment gateway callback adapter. */
    private String callbackSecret;
}
