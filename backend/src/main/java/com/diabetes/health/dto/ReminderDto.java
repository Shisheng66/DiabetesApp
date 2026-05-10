package com.diabetes.health.dto;

import com.diabetes.health.entity.HealthReminder;
import com.diabetes.health.util.DisplayLabel;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalTime;
import java.util.List;

public class ReminderDto {

    @Data
    public static class CreateReminderRequest {
        @NotNull(message = "提醒类型不能为空")
        @Pattern(regexp = "GLUCOSE_TEST|MEDICINE|EXERCISE|DIET|血糖提醒|用药提醒|运动提醒|饮食提醒", message = "提醒类型选择不正确")
        private String type;  // GLUCOSE_TEST, MEDICINE, EXERCISE, DIET
        @NotNull(message = "提醒时间不能为空")
        private LocalTime timeOfDay;
        @Pattern(regexp = "DAILY|WORKDAY|CUSTOM|每天|工作日|自定义", message = "重复方式选择不正确")
        private String repeatType;  // DAILY, WORKDAY, CUSTOM
        private Boolean enabled = true;
        @Size(max = 200, message = "备注不能超过200字")
        private String remark;
    }

    @Data
    public static class UpdateReminderRequest {
        private LocalTime timeOfDay;
        @Pattern(regexp = "DAILY|WORKDAY|CUSTOM|每天|工作日|自定义", message = "重复方式选择不正确")
        private String repeatType;
        private Boolean enabled;
        @Size(max = 200, message = "备注不能超过200字")
        private String remark;
    }

    @Data
    public static class ReminderResponse {
        private Long id;
        private String type;
        private LocalTime timeOfDay;
        private String repeatType;
        private Boolean enabled;
        private String remark;

        public static ReminderResponse from(HealthReminder r) {
            if (r == null) return null;
            ReminderResponse res = new ReminderResponse();
            res.setId(r.getId());
            res.setType(DisplayLabel.reminderType(r.getType()));
            res.setTimeOfDay(r.getTimeOfDay());
            res.setRepeatType(DisplayLabel.repeatType(r.getRepeatType()));
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
        @Pattern(regexp = "ANDROID|IOS|WEB", message = "设备类型选择不正确")
        private String deviceType;  // ANDROID, IOS
        @NotNull(message = "pushToken 不能为空")
        @Size(max = 512, message = "pushToken 过长")
        private String pushToken;
    }
}
