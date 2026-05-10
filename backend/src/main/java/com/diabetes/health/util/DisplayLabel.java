package com.diabetes.health.util;

import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.HealthReminder;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;

public final class DisplayLabel {

    private DisplayLabel() {
    }

    public static String measureType(BloodGlucoseRecord.MeasureType value) {
        if (value == null) return null;
        return switch (value) {
            case FASTING -> "空腹";
            case POST_MEAL -> "餐后";
            case BEFORE_SLEEP -> "睡前";
            case RANDOM -> "随机";
        };
    }

    public static String glucoseSource(BloodGlucoseRecord.RecordSource value) {
        if (value == null) return null;
        return switch (value) {
            case MANUAL -> "手动记录";
            case BLE -> "设备同步";
        };
    }

    public static String abnormal(BloodGlucoseRecord.AbnormalFlag value) {
        if (value == null) return null;
        return switch (value) {
            case NORMAL -> "正常";
            case HIGH -> "偏高";
            case LOW -> "偏低";
        };
    }

    public static String mealType(DietRecord.MealType value) {
        if (value == null) return null;
        return switch (value) {
            case BREAKFAST -> "早餐";
            case LUNCH -> "午餐";
            case DINNER -> "晚餐";
            case SNACK -> "加餐";
        };
    }

    public static String reminderType(HealthReminder.ReminderType value) {
        if (value == null) return null;
        return switch (value) {
            case GLUCOSE_TEST -> "血糖提醒";
            case MEDICINE -> "用药提醒";
            case EXERCISE -> "运动提醒";
            case DIET -> "饮食提醒";
        };
    }

    public static String repeatType(HealthReminder.RepeatType value) {
        if (value == null) return null;
        return switch (value) {
            case DAILY -> "每天";
            case WORKDAY -> "工作日";
            case CUSTOM -> "自定义";
        };
    }

    public static String gender(UserHealthProfile.Gender value) {
        if (value == null) return null;
        return switch (value) {
            case MALE -> "男";
            case FEMALE -> "女";
            case UNKNOWN -> "未说明";
        };
    }

    public static String diabetesType(UserHealthProfile.DiabetesType value) {
        if (value == null) return null;
        return switch (value) {
            case TYPE1 -> "一型";
            case TYPE2 -> "二型";
            case GESTATIONAL -> "妊娠期";
            case OTHER -> "1.5型/其他";
        };
    }

    public static String role(UserAccount.Role value) {
        if (value == null) return "病友";
        return switch (value) {
            case ADMIN -> "官方";
            case DOCTOR -> "医生";
            case FAMILY -> "家属";
            case PATIENT -> "病友";
        };
    }
}
