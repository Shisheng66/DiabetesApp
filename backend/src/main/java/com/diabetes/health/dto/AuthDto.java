package com.diabetes.health.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;

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
        @Size(min = 8, max = 64, message = "密码长度需为8-64位")
        @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)\\S{8,64}$", message = "密码需同时包含字母和数字，且不能包含空格")
        private String password;

        @NotBlank(message = "短信验证码不能为空")
        @Pattern(regexp = "\\d{6}", message = "短信验证码格式不正确")
        private String smsCode;
    }

    @Data
    public static class LoginRequest {
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "1[3-9]\\d{9}", message = "手机号格式不正确")
        private String phone;

        @Size(max = 128, message = "密码格式不正确")
        private String password;

        @Pattern(regexp = "\\d{6}", message = "短信验证码格式不正确")
        private String smsCode;

        @Size(max = 80, message = "图形验证码已失效，请刷新后重试")
        private String captchaChallengeId;

        @Size(min = 4, max = 8, message = "图形验证码格式不正确")
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
        private String phone;
        private String nickname;
        private String avatarUrl;
        private Object healthProfile;  // 可为 null 或健康档案摘要
    }

    @Data
    @EqualsAndHashCode(callSuper = true)
    public static class AdminUserInfo extends UserInfo {
        private Long id;
        private String role;
    }

    @Data
    public static class CaptchaResponse {
        private String challengeId;
        private String imageDataUri;
        private String imageMimeType;
        @JsonInclude(JsonInclude.Include.NON_EMPTY)
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

        @Size(max = 80, message = "图形验证码已失效，请刷新后重试")
        private String captchaChallengeId;

        @Size(min = 4, max = 8, message = "图形验证码格式不正确")
        private String captchaCode;
    }

    @Data
    public static class SendSmsCodeResponse {
        private Long cooldownSeconds;
        private Long expiresInSeconds;
        @JsonInclude(JsonInclude.Include.NON_EMPTY)
        private String debugCode;
        private String message;
    }
}
