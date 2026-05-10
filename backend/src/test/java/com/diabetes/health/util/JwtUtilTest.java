package com.diabetes.health.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class JwtUtilTest {

    @Test
    void generateAndValidateToken() {
        JwtUtil jwtUtil = new JwtUtil(
                "test-secret-key-for-jwt-validation-32chars",
                3600
        );

        String token = jwtUtil.generate(123L);

        assertThat(jwtUtil.validate(token)).isTrue();
        assertThat(jwtUtil.getUserId(token)).isEqualTo(123L);
        assertThat(jwtUtil.parse(token).get("role")).isNull();
        assertThat(jwtUtil.parse(token).get("phone")).isNull();
    }

    @Test
    void validateRejectsBrokenToken() {
        JwtUtil jwtUtil = new JwtUtil(
                "test-secret-key-for-jwt-validation-32chars",
                3600
        );

        assertThat(jwtUtil.validate("broken.token.value")).isFalse();
    }
}
