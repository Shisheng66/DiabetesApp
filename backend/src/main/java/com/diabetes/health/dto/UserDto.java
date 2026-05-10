package com.diabetes.health.dto;

import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.util.DisplayLabel;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

public class UserDto {

    @Data
    public static class UpdateMeRequest {
        @Size(max = 50, message = "昵称不能超过50字")
        private String nickname;
        @Size(max = 500, message = "头像URL不能超过500字")
        private String avatarUrl;
    }

    @Data
    public static class HealthProfileResponse {
        private Long id;
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
            r.setNickname(p.getNickname());
            r.setAvatarUrl(p.getAvatarUrl());
            r.setGender(DisplayLabel.gender(p.getGender()));
            r.setBirthDate(p.getBirthDate());
            r.setHeightCm(p.getHeightCm());
            r.setWeightKg(p.getWeightKg());
            r.setDiabetesType(DisplayLabel.diabetesType(p.getDiabetesType()));
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
        @Size(max = 50, message = "昵称不能超过50字")
        private String nickname;
        @Size(max = 500, message = "头像URL不能超过500字")
        private String avatarUrl;
        @Pattern(regexp = "MALE|FEMALE|UNKNOWN", message = "性别选择不正确")
        private String gender;       // MALE, FEMALE, UNKNOWN
        private LocalDate birthDate;
        @DecimalMin(value = "30", message = "身高不能低于30cm")
        @DecimalMax(value = "250", message = "身高不能超过250cm")
        private Integer heightCm;
        @DecimalMin(value = "10", message = "体重不能低于10kg")
        @DecimalMax(value = "300", message = "体重不能超过300kg")
        private BigDecimal weightKg;
        @Pattern(regexp = "TYPE1|TYPE2|OTHER|GESTATIONAL|TYPE_1|TYPE_2|TYPE_1_5|LADA|一型|二型|1\\.5型|妊娠期|其他", message = "糖尿病类型选择不正确")
        private String diabetesType;
        private LocalDate diagnosisDate;
        @Size(max = 100, message = "用药情况不能超过100字")
        private String medicationStatus;
        @DecimalMin(value = "2.0", message = "空腹目标下限不能低于2.0")
        @DecimalMax(value = "20.0", message = "空腹目标下限不能超过20.0")
        private BigDecimal targetFbgMin;
        @DecimalMin(value = "2.0", message = "空腹目标上限不能低于2.0")
        @DecimalMax(value = "20.0", message = "空腹目标上限不能超过20.0")
        private BigDecimal targetFbgMax;
        @DecimalMin(value = "2.0", message = "餐后目标下限不能低于2.0")
        @DecimalMax(value = "25.0", message = "餐后目标下限不能超过25.0")
        private BigDecimal targetPbgMin;
        @DecimalMin(value = "2.0", message = "餐后目标上限不能低于2.0")
        @DecimalMax(value = "25.0", message = "餐后目标上限不能超过25.0")
        private BigDecimal targetPbgMax;
        @Size(max = 500, message = "备注不能超过500字")
        private String remark;
    }

    @Data
    public static class ChangePasswordRequest {
        @NotBlank(message = "旧密码不能为空")
        @Size(max = 128, message = "旧密码格式不正确")
        private String oldPassword;
        @NotBlank(message = "新密码不能为空")
        @Size(min = 8, max = 64, message = "密码长度需为8-64位")
        @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)\\S{8,64}$", message = "密码需同时包含字母和数字，且不能包含空格")
        private String newPassword;
    }
}
