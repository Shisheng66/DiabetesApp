package com.diabetes.health.controller;

import com.diabetes.health.dto.AuthDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.client.ResponseErrorHandler;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 集成测试基类 — 提供注册/登录辅助方法。
 */
public abstract class BaseIntegrationTest {

    @Autowired
    protected TestRestTemplate rest;

    @Autowired
    protected ObjectMapper mapper;

    /** 让 TestRestTemplate 不要在 4xx 时抛异常。 */
    protected TestRestTemplate noThrowRest() {
        TestRestTemplate t = rest;
        t.getRestTemplate().setErrorHandler(new ResponseErrorHandler() {
            @Override public boolean hasError(ClientHttpResponse r) { return false; }
            @Override public void handleError(ClientHttpResponse r) {}
        });
        return t;
    }

    // ── 辅助方法 ──────────────────────────────────────────────

    /** 走完整注册流程：captcha → sms/send → register，返回 token。 */
    protected String registerUser(String phone, String password) {
        TestRestTemplate rt = noThrowRest();
        // 1. 获取验证码
        var captchaResp = rt.getForEntity("/api/auth/captcha", AuthDto.CaptchaResponse.class);
        assertThat(captchaResp.getStatusCode()).isEqualTo(HttpStatus.OK);
        String challengeId = captchaResp.getBody().getChallengeId();
        String captchaCode = captchaResp.getBody().getDisplayCode();

        // 2. 发送短信
        var smsReq = new AuthDto.SendSmsCodeRequest();
        smsReq.setPhone(phone);
        smsReq.setScene(AuthDto.SmsScene.REGISTER);
        smsReq.setCaptchaChallengeId(challengeId);
        smsReq.setCaptchaCode(captchaCode);
        var smsResp = rt.postForEntity("/api/auth/sms/send", smsReq, AuthDto.SendSmsCodeResponse.class);
        assertThat(smsResp.getStatusCode())
            .as("SMS send failed")
            .isEqualTo(HttpStatus.OK);
        String smsCode = smsResp.getBody().getDebugCode();

        // 3. 注册
        var regReq = new AuthDto.RegisterRequest();
        regReq.setPhone(phone);
        regReq.setPassword(password);
        regReq.setSmsCode(smsCode);
        var regResp = rt.postForEntity("/api/auth/register", regReq, AuthDto.LoginResponse.class);
        assertThat(regResp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return regResp.getBody().getAccessToken();
    }

    /** 走密码登录流程：captcha → login，返回 token。 */
    protected String loginUser(String phone, String password) {
        TestRestTemplate rt = noThrowRest();
        var captchaResp = rt.getForEntity("/api/auth/captcha", AuthDto.CaptchaResponse.class);
        String challengeId = captchaResp.getBody().getChallengeId();
        String captchaCode = captchaResp.getBody().getDisplayCode();

        var loginReq = new AuthDto.LoginRequest();
        loginReq.setPhone(phone);
        loginReq.setPassword(password);
        loginReq.setLoginType(AuthDto.LoginType.PASSWORD);
        loginReq.setCaptchaChallengeId(challengeId);
        loginReq.setCaptchaCode(captchaCode);
        var resp = rt.postForEntity("/api/auth/login", loginReq, AuthDto.LoginResponse.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        return resp.getBody().getAccessToken();
    }

    /** 带 Authorization header 的请求头。 */
    protected HttpHeaders authHeaders(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    /** 发送带认证的 GET 请求。 */
    protected <T> ResponseEntity<T> authGet(String url, String token, Class<T> type) {
        return noThrowRest().exchange(url, HttpMethod.GET, new HttpEntity<>(authHeaders(token)), type);
    }

    /** 发送带认证的 POST 请求。 */
    protected <T> ResponseEntity<T> authPost(String url, String token, Object body, Class<T> type) {
        return noThrowRest().exchange(url, HttpMethod.POST, new HttpEntity<>(body, authHeaders(token)), type);
    }

    /** 发送带认证的 PUT 请求。 */
    protected <T> ResponseEntity<T> authPut(String url, String token, Object body, Class<T> type) {
        return noThrowRest().exchange(url, HttpMethod.PUT, new HttpEntity<>(body, authHeaders(token)), type);
    }

    /** 发送带认证的 DELETE 请求。 */
    protected <T> ResponseEntity<T> authDelete(String url, String token, Class<T> type) {
        return noThrowRest().exchange(url, HttpMethod.DELETE, new HttpEntity<>(authHeaders(token)), type);
    }
}
