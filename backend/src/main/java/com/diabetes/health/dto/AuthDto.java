package com.diabetes.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

public class AuthDto {

    @Data
    public static class RegisterRequest {
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "1[3-9]\\d{9}", message = "手机号格式不正确")
        private String phone;

        @NotBlank(message = "密码不能为空")
        @Size(min = 6, max = 32, message = "密码长度6-32位")
        private String password;

        private String role = "PATIENT";  // PATIENT, DOCTOR, FAMILY, ADMIN
    }

    @Data
    public static class LoginRequest {
        @NotBlank(message = "手机号不能为空")
        private String phone;

        @NotBlank(message = "密码不能为空")
        private String password;
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
}
