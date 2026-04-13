package com.diabetes.health.dto;

import com.diabetes.health.entity.BloodGlucoseRecord;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public class BloodGlucoseDto {

    @Data
    public static class CreateRecordRequest {
        @NotNull(message = "测量时间不能为空")
        private Instant measureTime;

        @NotNull(message = "测量类型不能为空")
        private String measureType;  // FASTING, POST_MEAL, BEFORE_SLEEP, RANDOM

        @NotNull(message = "血糖值不能为空")
        @DecimalMin(value = "0", message = "血糖值必须≥0")
        private BigDecimal valueMmolL;

        private String source = "MANUAL";  // MANUAL, BLE
        private Long deviceId;
        private String remark;
    }

    @Data
    public static class RecordResponse {
        private Long id;
        private Long userId;
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
            res.setUserId(r.getUserId());
            res.setMeasureTime(r.getMeasureTime());
            res.setMeasureType(r.getMeasureType() != null ? r.getMeasureType().name() : null);
            res.setValueMmolL(r.getValueMmolL());
            res.setSource(r.getSource() != null ? r.getSource().name() : null);
            res.setDeviceId(r.getDeviceId());
            res.setRemark(r.getRemark());
            res.setAbnormalFlag(r.getAbnormalFlag() != null ? r.getAbnormalFlag().name() : null);
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
}
