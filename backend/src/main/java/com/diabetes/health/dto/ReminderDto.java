package com.diabetes.health.dto;

import com.diabetes.health.entity.HealthReminder;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalTime;
import java.util.List;

public class ReminderDto {

    @Data
    public static class CreateReminderRequest {
        @NotNull(message = "提醒类型不能为空")
        private String type;  // GLUCOSE_TEST, MEDICINE, EXERCISE, DIET
        private LocalTime timeOfDay;
        private String repeatType;  // DAILY, WORKDAY, CUSTOM
        private Boolean enabled = true;
        private String remark;
    }

    @Data
    public static class UpdateReminderRequest {
        private LocalTime timeOfDay;
        private String repeatType;
        private Boolean enabled;
        private String remark;
    }

    @Data
    public static class ReminderResponse {
        private Long id;
        private Long userId;
        private String type;
        private LocalTime timeOfDay;
        private String repeatType;
        private Boolean enabled;
        private String remark;

        public static ReminderResponse from(HealthReminder r) {
            if (r == null) return null;
            ReminderResponse res = new ReminderResponse();
            res.setId(r.getId());
            res.setUserId(r.getUserId());
            res.setType(r.getType() != null ? r.getType().name() : null);
            res.setTimeOfDay(r.getTimeOfDay());
            res.setRepeatType(r.getRepeatType() != null ? r.getRepeatType().name() : null);
            res.setEnabled(r.getEnabled());
            res.setRemark(r.getRemark());
            return res;
        }
    }

    @Data
    public static class ListResponse {
        private int code;
        private List<ReminderResponse> data;

        public static ListResponse of(List<ReminderResponse> reminders) {
            ListResponse response = new ListResponse();
            response.setCode(200);
            response.setData(reminders);
            return response;
        }
    }

    @Data
    public static class RegisterPushRequest {
        private String deviceType;  // ANDROID, IOS
        @NotNull(message = "pushToken 不能为空")
        private String pushToken;
    }
}
