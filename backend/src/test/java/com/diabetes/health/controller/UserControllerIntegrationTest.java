package com.diabetes.health.controller;

import com.diabetes.health.dto.UserDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class UserControllerIntegrationTest extends BaseIntegrationTest {

    private static String token;

    @BeforeEach
    void setUp() {
        if (token == null) {
            token = registerUser("13930000031", "Test1234");
        }
    }

    @Test
    void getMe_returnsUserInfo() {
        var resp = authGet("/api/users/me", token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).contains("13930000031");
    }

    @Test
    void updateMe_nickname() {
        var req = new UserDto.UpdateMeRequest();
        req.setNickname("新昵称");
        var resp = authPut("/api/users/me", token, req, Void.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 验证更新生效
        var me = authGet("/api/users/me", token, String.class);
        assertThat(me.getBody()).contains("新昵称");
    }

    @Test
    void getHealthProfile_returnsDefaultProfile() {
        var resp = authGet("/api/users/me/health-profile", token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).isNotBlank();
    }

    @Test
    void updateHealthProfile_happyPath() {
        var req = new UserDto.UpdateHealthProfileRequest();
        req.setGender("MALE");
        req.setBirthDate(LocalDate.of(1990, 1, 1));
        req.setHeightCm(175);
        req.setWeightKg(new BigDecimal("70.5"));
        req.setDiabetesType("TYPE2");
        req.setTargetFbgMin(new BigDecimal("3.9"));
        req.setTargetFbgMax(new BigDecimal("6.1"));
        req.setTargetPbgMin(new BigDecimal("5.0"));
        req.setTargetPbgMax(new BigDecimal("7.8"));

        var resp = authPut("/api/users/me/health-profile", token, req, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).contains("男"); // DisplayLabel converts MALE → 男
    }

    @Test
    void updateHealthProfile_invalidHeight_returns400() {
        var req = new UserDto.UpdateHealthProfileRequest();
        req.setHeightCm(10); // 低于最小值 30
        var resp = authPut("/api/users/me/health-profile", token, req, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void changePassword_happyPath() {
        var req = new UserDto.ChangePasswordRequest();
        req.setOldPassword("Test1234");
        req.setNewPassword("NewPass123");
        var resp = authPut("/api/users/me/password", token, req, Void.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 用新密码登录
        String newToken = loginUser("13930000031", "NewPass123");
        assertThat(newToken).isNotBlank();
    }

    @Test
    void changePassword_wrongOldPassword_returns400() {
        var req = new UserDto.ChangePasswordRequest();
        req.setOldPassword("WrongOld1");
        req.setNewPassword("NewPass123");
        var resp = authPut("/api/users/me/password", token, req, String.class);
        assertThat(resp.getStatusCode()).isIn(HttpStatus.BAD_REQUEST, HttpStatus.UNAUTHORIZED);
    }

    @Test
    void changePassword_weakNewPassword_returns400() {
        var req = new UserDto.ChangePasswordRequest();
        req.setOldPassword("Test1234");
        req.setNewPassword("123"); // 太短
        var resp = authPut("/api/users/me/password", token, req, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
