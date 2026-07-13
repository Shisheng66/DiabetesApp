package com.diabetes.health.controller;

import com.diabetes.health.config.PaymentProperties;
import com.diabetes.health.dto.CommercialDto;
import com.diabetes.health.dto.PaymentDto;
import com.diabetes.health.service.CommercialService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Payment providers call this endpoint after a successful payment.
 * A provider-specific adapter must translate its verified notification into this contract.
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentCallbackController {

    private final CommercialService commercialService;
    private final PaymentProperties paymentProperties;
    private final ObjectMapper objectMapper;
    private final Validator validator;

    @PostMapping("/callback")
    public CommercialDto.SubscriptionResponse callback(
            @RequestHeader(value = "X-Payment-Signature", required = false) String signature,
            @RequestBody String rawBody
    ) {
        verifySignature(rawBody, signature);
        PaymentDto.CallbackRequest request;
        try {
            request = objectMapper.readValue(rawBody, PaymentDto.CallbackRequest.class);
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "支付回调格式错误");
        }
        if (!validator.validate(request).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "支付回调参数错误");
        }
        return commercialService.confirmPaidOrder(request);
    }

    private void verifySignature(String rawBody, String signature) {
        String secret = paymentProperties.getCallbackSecret();
        if (secret == null || secret.isBlank() || signature == null || signature.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "支付回调签名无效");
        }
        String expected = hmacSha256(rawBody, secret);
        String provided = signature.startsWith("sha256=") ? signature.substring("sha256=".length()) : signature;
        if (!MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                provided.getBytes(StandardCharsets.UTF_8)
        )) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "支付回调签名无效");
        }
    }

    private String hmacSha256(String value, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return java.util.HexFormat.of().formatHex(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception ex) {
            throw new IllegalStateException("支付回调签名校验不可用", ex);
        }
    }
}
