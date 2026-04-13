package com.diabetes.health.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

public class DashboardDto {

    @Data
    public static class TodayResponse {
        private BloodGlucoseDto.RecordResponse latestGlucose;
        private BigDecimal todayTotalCalorieBurned;
        private BigDecimal todayTotalCalorieEaten;
        private List<String> reminders;
    }
}
