package com.diabetes.health.service;

import com.diabetes.health.config.SmsProperties;
import com.diabetes.health.dto.AuthDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

@Slf4j
@Service
@Profile("prod")
@RequiredArgsConstructor
public class HttpSmsSender implements SmsSender {

    private final SmsProperties smsProperties;
    private final ObjectMapper objectMapper;

    @Override
    public void sendVerificationCode(String phone, String code, AuthDto.SmsScene scene) {
        if (smsProperties.getEndpoint() == null || smsProperties.getEndpoint().isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "短信服务暂未配置");
        }

        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("phone", phone);
            payload.put("code", code);
            payload.put("scene", scene.name());
            payload.put("signature", smsProperties.getSignature());
            payload.put("templateId", smsProperties.getTemplateId());

            HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                    .uri(URI.create(smsProperties.getEndpoint()))
                    .timeout(Duration.ofSeconds(Math.max(1, smsProperties.getRequestTimeoutSeconds())))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)));

            if (smsProperties.getToken() != null && !smsProperties.getToken().isBlank()) {
                requestBuilder.header("Authorization", "Bearer " + smsProperties.getToken());
            }

            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(Math.max(1, smsProperties.getConnectTimeoutSeconds())))
                    .build();
            HttpResponse<String> response = client.send(requestBuilder.build(), HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                log.warn("短信服务返回异常状态 status={} scene={}", response.statusCode(), scene);
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "短信服务暂时不可用");
            }
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            log.warn("短信发送失败 scene={} reason={}", scene, ex.getMessage());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "短信发送失败，请稍后重试");
        }
    }
}
