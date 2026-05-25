package com.diabetes.health.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public class DoctorDto {

    @Data
    public static class PatientSummary {
        private Long patientId;
        private String phoneMasked;
        private String nickname;
        private String diabetesType;
        private Instant lastLoginAt;
        private Long abnormalCount;
    }

    @Data
    public static class AlertResponse {
        private Long id;
        private Long patientId;
        private String patientName;
        private String type;
        private String level;
        private Boolean handled;
        private Instant createdAt;
    }

    @Data
    public static class PatientReportResponse {
        private Long patientId;
        private String patientName;
        private String diabetesType;
        private Long abnormalCount;
        private List<GlucosePoint> recentGlucose;
    }

    @Data
    public static class GlucosePoint {
        private Instant measureTime;
        private String measureType;
        private BigDecimal valueMmolL;
        private String abnormalFlag;
    }
}
