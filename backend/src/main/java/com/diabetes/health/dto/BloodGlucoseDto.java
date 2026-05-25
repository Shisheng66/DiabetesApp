package com.diabetes.health.dto;

import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.util.DisplayLabel;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public class BloodGlucoseDto {

    @Data
    public static class CreateRecordRequest {
        @NotNull(message = "测量时间不能为空")
        private Instant measureTime;

        @NotNull(message = "测量类型不能为空")
        @Pattern(regexp = "FASTING|POST_MEAL|BEFORE_SLEEP|RANDOM|空腹|餐后|睡前|随机", message = "测量时段选择不正确")
        private String measureType;  // FASTING, POST_MEAL, BEFORE_SLEEP, RANDOM

        @NotNull(message = "血糖值不能为空")
        @DecimalMin(value = "1.0", message = "血糖值不能低于1.0")
        @DecimalMax(value = "33.3", message = "血糖值不能超过33.3")
        private BigDecimal valueMmolL;

        @Pattern(regexp = "MANUAL|BLE|手动记录|设备同步", message = "记录来源选择不正确")
        private String source = "MANUAL";  // MANUAL, BLE
        private Long deviceId;
        @Size(max = 200, message = "备注不能超过200字")
        private String remark;
    }

    @Data
    public static class RecordResponse {
        private Long id;
        private Instant measureTime;
        private String measureType;
        private BigDecimal valueMmolL;
        private String source;
        private Long deviceId;
        private String remark;
        private String abnormalFlag;
        private Instant createdAt;

        public static RecordResponse from(BloodGlucoseRecord r) {
            if (r == null) return null;
            RecordResponse res = new RecordResponse();
            res.setId(r.getId());
            res.setMeasureTime(r.getMeasureTime());
            res.setMeasureType(DisplayLabel.measureType(r.getMeasureType()));
            res.setValueMmolL(r.getValueMmolL());
            res.setSource(DisplayLabel.glucoseSource(r.getSource()));
            res.setDeviceId(r.getDeviceId());
            res.setRemark(r.getRemark());
            res.setAbnormalFlag(DisplayLabel.abnormal(r.getAbnormalFlag()));
            res.setCreatedAt(r.getCreatedAt());
            return res;
        }
    }

    @Data
    @EqualsAndHashCode(callSuper = true)
    public static class AdminRecordResponse extends RecordResponse {
        private Long userId;
        private String measureTypeRaw;
        private String sourceRaw;
        private String abnormalFlagRaw;

        public static AdminRecordResponse from(BloodGlucoseRecord r) {
            if (r == null) return null;
            AdminRecordResponse res = new AdminRecordResponse();
            res.setId(r.getId());
            res.setUserId(r.getUserId());
            res.setMeasureTime(r.getMeasureTime());
            res.setMeasureType(DisplayLabel.measureType(r.getMeasureType()));
            res.setMeasureTypeRaw(r.getMeasureType() != null ? r.getMeasureType().name() : null);
            res.setValueMmolL(r.getValueMmolL());
            res.setSource(DisplayLabel.glucoseSource(r.getSource()));
            res.setSourceRaw(r.getSource() != null ? r.getSource().name() : null);
            res.setDeviceId(r.getDeviceId());
            res.setRemark(r.getRemark());
            res.setAbnormalFlag(DisplayLabel.abnormal(r.getAbnormalFlag()));
            res.setAbnormalFlagRaw(r.getAbnormalFlag() != null ? r.getAbnormalFlag().name() : null);
            res.setCreatedAt(r.getCreatedAt());
            return res;
        }
    }

    @Data
    public static class TrendPoint {
        private String time;   // 日期或时间点
        private BigDecimal value;
    }

    @Data
    public static class TrendResponse {
        private String periodType;  // daily, weekly, monthly
        private List<TrendPoint> points;
    }

    @Data
    public static class PageResult<T> {
        private List<T> content;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;
    }

    @Data
    public static class AbnormalEventResponse {
        private Long id;
        private Long recordId;
        private String type;
        private String level;
        private Boolean handled;
        private Instant createdAt;

        public static AbnormalEventResponse from(
                com.diabetes.health.entity.GlucoseAbnormalEvent e
        ) {
            if (e == null) return null;
            AbnormalEventResponse r = new AbnormalEventResponse();
            r.setId(e.getId());
            r.setRecordId(e.getRecordId());
            r.setType(e.getType() == null ? null : (e.getType().name().equals("HIGH") ? "偏高" : "偏低"));
            r.setLevel(e.getLevel());
            r.setHandled(e.getHandled());
            r.setCreatedAt(e.getCreatedAt());
            return r;
        }
    }
}
