package com.diabetes.health.dto;

import com.diabetes.health.entity.UserHealthProfile;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

public class UserDto {

    @Data
    public static class UpdateMeRequest {
        private String nickname;
        private String avatarUrl;
    }

    @Data
    public static class HealthProfileResponse {
        private Long id;
        private Long userId;
        private String nickname;
        private String avatarUrl;
        private String gender;
        private LocalDate birthDate;
        private Integer heightCm;
        private BigDecimal weightKg;
        private String diabetesType;
        private LocalDate diagnosisDate;
        private String medicationStatus;
        private BigDecimal targetFbgMin;
        private BigDecimal targetFbgMax;
        private BigDecimal targetPbgMin;
        private BigDecimal targetPbgMax;
        private String remark;

        public static HealthProfileResponse from(UserHealthProfile p) {
            if (p == null) return null;
            HealthProfileResponse r = new HealthProfileResponse();
            r.setId(p.getId());
            r.setUserId(p.getUserId());
            r.setNickname(p.getNickname());
            r.setAvatarUrl(p.getAvatarUrl());
            r.setGender(p.getGender() != null ? p.getGender().name() : null);
            r.setBirthDate(p.getBirthDate());
            r.setHeightCm(p.getHeightCm());
            r.setWeightKg(p.getWeightKg());
            r.setDiabetesType(p.getDiabetesType() != null ? p.getDiabetesType().name() : null);
            r.setDiagnosisDate(p.getDiagnosisDate());
            r.setMedicationStatus(p.getMedicationStatus());
            r.setTargetFbgMin(p.getTargetFbgMin());
            r.setTargetFbgMax(p.getTargetFbgMax());
            r.setTargetPbgMin(p.getTargetPbgMin());
            r.setTargetPbgMax(p.getTargetPbgMax());
            r.setRemark(p.getRemark());
            return r;
        }
    }

    @Data
    public static class UpdateHealthProfileRequest {
        private String nickname;
        private String avatarUrl;
        private String gender;       // MALE, FEMALE, UNKNOWN
        private LocalDate birthDate;
        private Integer heightCm;
        private BigDecimal weightKg;
        private String diabetesType; // TYPE1, TYPE2, GESTATIONAL, OTHER
        private LocalDate diagnosisDate;
        private String medicationStatus;
        private BigDecimal targetFbgMin;
        private BigDecimal targetFbgMax;
        private BigDecimal targetPbgMin;
        private BigDecimal targetPbgMax;
        private String remark;
    }

    @Data
    public static class ChangePasswordRequest {
        private String oldPassword;
        private String newPassword;
    }
}
