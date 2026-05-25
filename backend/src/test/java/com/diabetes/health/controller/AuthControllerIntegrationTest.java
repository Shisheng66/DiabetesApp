package com.diabetes.health.controller;

import com.diabetes.health.dto.AuthDto;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthControllerIntegrationTest extends BaseIntegrationTest {

    private static final String PHONE = "13900000011";
    private static final String PASSWORD = "Test1234";

    @Test
    void captcha_returnsValidChallenge() {
        var resp = noThrowRest().getForEntity("/api/auth/captcha", AuthDto.CaptchaResponse.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody().getChallengeId()).isNotBlank();
        assertThat(resp.getBody().getImageDataUri()).startsWith("data:image/png");
        assertThat(resp.getBody().getDisplayCode()).isNotBlank();
    }

    @Test
    void register_happyPath() {
        String token = registerUser(PHONE, PASSWORD);
        assertThat(token).isNotBlank();
    }

    @Test
    void register_duplicatePhone_returns400() {
        registerUser("13900000012", PASSWORD);

        var captchaResp = noThrowRest().getForEntity("/api/auth/captcha", AuthDto.CaptchaResponse.class);
        var smsReq = new AuthDto.SendSmsCodeRequest();
        smsReq.setPhone("13900000012");
        smsReq.setScene(AuthDto.SmsScene.REGISTER);
        smsReq.setCaptchaChallengeId(captchaResp.getBody().getChallengeId());
        smsReq.setCaptchaCode(captchaResp.getBody().getDisplayCode());
        var smsResp = noThrowRest().postForEntity("/api/auth/sms/send", smsReq, String.class);
        // 该手机号已注册，SMS send 应返回 400
        assertThat(smsResp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void login_password_happyPath() {
        registerUser("13900000013", PASSWORD);
        String token = loginUser("13900000013", PASSWORD);
        assertThat(token).isNotBlank();
    }

    @Test
    void login_wrongPassword_returns401() {
        registerUser("13900000014", PASSWORD);
        try {
            var captchaResp = noThrowRest().getForEntity("/api/auth/captcha", AuthDto.CaptchaResponse.class);
            var loginReq = new AuthDto.LoginRequest();
            loginReq.setPhone("13900000014");
            loginReq.setPassword("WrongPass1");
            loginReq.setLoginType(AuthDto.LoginType.PASSWORD);
            loginReq.setCaptchaChallengeId(captchaResp.getBody().getChallengeId());
            loginReq.setCaptchaCode(captchaResp.getBody().getDisplayCode());
            var resp = noThrowRest().postForEntity("/api/auth/login", loginReq, String.class);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        } catch (org.springframework.web.client.ResourceAccessException e) {
            // TestRestTemplate 的 HTTP 客户端可能对 401 抛出 I/O 异常
            assertThat(e.getMessage()).contains("server authentication");
        }
    }

    @Test
    void login_nonExistentPhone_returns401() {
        try {
            var captchaResp = noThrowRest().getForEntity("/api/auth/captcha", AuthDto.CaptchaResponse.class);
            var loginReq = new AuthDto.LoginRequest();
            loginReq.setPhone("13999999999");
            loginReq.setPassword(PASSWORD);
            loginReq.setLoginType(AuthDto.LoginType.PASSWORD);
            loginReq.setCaptchaChallengeId(captchaResp.getBody().getChallengeId());
            loginReq.setCaptchaCode(captchaResp.getBody().getDisplayCode());
            var resp = noThrowRest().postForEntity("/api/auth/login", loginReq, String.class);
            assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        } catch (org.springframework.web.client.ResourceAccessException e) {
            assertThat(e.getMessage()).contains("server authentication");
        }
    }

    @Test
    void logout_blacklistsToken() {
        String token = registerUser("13900000015", PASSWORD);

        var headers = authHeaders(token);
        var logoutResp = noThrowRest().exchange("/api/auth/logout", org.springframework.http.HttpMethod.POST,
                new org.springframework.http.HttpEntity<>(headers), Void.class);
        assertThat(logoutResp.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 登出后用原 token 访问受保护接口应 403
        var meResp = authGet("/api/users/me", token, String.class);
        assertThat(meResp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }
}
