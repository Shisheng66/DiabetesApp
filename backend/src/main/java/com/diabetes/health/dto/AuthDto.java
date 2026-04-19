package com.diabetes.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

public class AuthDto {

    public enum LoginType {
        PASSWORD, SMS
    }

    public enum SmsScene {
        REGISTER, LOGIN
    }

    @Data
    public static class RegisterRequest {
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "1[3-9]\\d{9}", message = "手机号格式不正确")
        private String phone;

        @NotBlank(message = "密码不能为空")
        @Size(min = 6, max = 32, message = "密码长度6-32位")
        private String password;

        @NotBlank(message = "短信验证码不能为空")
        @Size(min = 4, max = 8, message = "短信验证码格式不正确")
        private String smsCode;

        private String role = "PATIENT";  // PATIENT, DOCTOR, FAMILY, ADMIN
    }

    @Data
    public static class LoginRequest {
        @NotBlank(message = "手机号不能为空")
        private String phone;

        private String password;

        private String smsCode;

        private String captchaChallengeId;

        private String captchaCode;

        private LoginType loginType = LoginType.PASSWORD;
    }

    @Data
    public static class LoginResponse {
        private String accessToken;
        private String tokenType = "Bearer";
        private UserInfo userInfo;

        public LoginResponse(String accessToken, UserInfo userInfo) {
            this.accessToken = accessToken;
            this.userInfo = userInfo;
        }
    }

    @Data
    public static class UserInfo {
        private Long id;
        private String phone;
        private String role;
        private String nickname;
        private String avatarUrl;
        private Object healthProfile;  // 可为 null 或健康档案摘要
    }

    @Data
    public static class CaptchaResponse {
        private String challengeId;
        private String displayCode;
        private Long expiresInSeconds;
    }

    @Data
    public static class SendSmsCodeRequest {
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "1[3-9]\\d{9}", message = "手机号格式不正确")
        private String phone;

        @NotNull(message = "短信场景不能为空")
        private SmsScene scene;

        private String captchaChallengeId;

        private String captchaCode;
    }

    @Data
    public static class SendSmsCodeResponse {
        private Long cooldownSeconds;
        private Long expiresInSeconds;
        private Boolean mock;
        private String debugCode;
        private String message;
    }
}
