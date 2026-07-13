package com.diabetes.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

import java.time.Instant;

public class DoctorAccessDto {

    @Data
    public static class GrantRequest {
        @NotBlank(message = "医生手机号不能为空")
        @Pattern(regexp = "1[3-9]\\d{9}", message = "医生手机号格式不正确")
        private String doctorPhone;
    }

    @Data
    public static class AccessResponse {
        private Long doctorId;
        private String doctorName;
        private String doctorPhoneMasked;
        private String status;
        private Instant grantedAt;
        private Instant revokedAt;
    }
}
