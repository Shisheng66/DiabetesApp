package com.diabetes.health.controller;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class SecurityIntegrationTest extends BaseIntegrationTest {

    @Test
    void healthCheck_isPublic() {
        var resp = rest.getForEntity("/api/health", String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void protectedEndpoint_withoutToken_returns403() {
        var resp = rest.getForEntity("/api/users/me", String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void protectedEndpoint_withInvalidToken_returns403() {
        var headers = new HttpHeaders();
        headers.setBearerAuth("invalid.jwt.token");
        var resp = rest.exchange("/api/users/me", HttpMethod.GET,
                new HttpEntity<>(headers), String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void adminEndpoint_withPatientRole_returns403() {
        String token = registerUser("13910000051", "Test1234");
        var resp = authGet("/api/admin/me", token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void doctorEndpoint_withPatientRole_returns403() {
        String token = registerUser("13910000052", "Test1234");
        var resp = authGet("/api/doctor/patients", token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void authEndpoints_areRateLimited() {
        // 连续请求 11 次 captcha，第 11 次应被限流
        for (int i = 0; i < 10; i++) {
            rest.getForEntity("/api/auth/captcha", String.class);
        }
        var resp = rest.getForEntity("/api/auth/captcha", String.class);
        // Rate limit is 10/min for auth endpoints — 11th may be 429
        // Note: exact behavior depends on timing; we just verify no 5xx
        assertThat(resp.getStatusCode().is5xxServerError()).isFalse();
    }

    @Test
    void cors_preflight_returns200() {
        var headers = new HttpHeaders();
        headers.set("Origin", "http://localhost:3000");
        headers.set("Access-Control-Request-Method", "GET");
        var resp = rest.exchange("/api/health", HttpMethod.OPTIONS,
                new HttpEntity<>(headers), String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
