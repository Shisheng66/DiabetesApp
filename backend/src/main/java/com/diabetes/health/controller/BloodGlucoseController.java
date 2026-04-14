package com.diabetes.health.controller;

import com.diabetes.health.dto.BloodGlucoseDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.BloodGlucoseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * 血糖记录与趋势（需登录）
 *
 * 新增端点：
 * GET /api/blood-glucose/abnormal-events   分页查询当前用户的血糖异常事件
 */
@RestController
@RequestMapping("/api/blood-glucose")
@RequiredArgsConstructor
public class BloodGlucoseController {

    private final BloodGlucoseService bloodGlucoseService;

    @PostMapping("/records")
    public BloodGlucoseDto.RecordResponse create(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody BloodGlucoseDto.CreateRecordRequest request) {
        return bloodGlucoseService.create(user, request);
    }

    @GetMapping("/records")
    public BloodGlucoseDto.PageResult<BloodGlucoseDto.RecordResponse> list(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String measureType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return bloodGlucoseService.list(user, startDate, endDate, measureType, page, size);
    }

    @GetMapping("/records/{id}")
    public BloodGlucoseDto.RecordResponse getById(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long id) {
        return bloodGlucoseService.getById(user, id);
    }

    @DeleteMapping("/records/{id}")
    public void delete(@AuthenticationPrincipal CurrentUser user, @PathVariable Long id) {
        bloodGlucoseService.delete(user, id);
    }

    @GetMapping("/trend/daily")
    public BloodGlucoseDto.TrendResponse trendDaily(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return bloodGlucoseService.trendDaily(user, date);
    }

    @GetMapping("/trend/weekly")
    public BloodGlucoseDto.TrendResponse trendWeekly(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        return bloodGlucoseService.trendWeekly(user, weekStart);
    }

    @GetMapping("/trend/monthly")
    public BloodGlucoseDto.TrendResponse trendMonthly(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam int year,
            @RequestParam int month) {
        return bloodGlucoseService.trendMonthly(user, year, month);
    }

    /**
     * 新增：查询当前用户的血糖异常事件列表（分页，按时间降序）
     * GET /api/blood-glucose/abnormal-events?page=0&size=50
     */
    @GetMapping("/abnormal-events")
    public BloodGlucoseDto.PageResult<BloodGlucoseDto.AbnormalEventResponse> listAbnormalEvents(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return bloodGlucoseService.listAbnormalEvents(user, page, size);
    }
}
