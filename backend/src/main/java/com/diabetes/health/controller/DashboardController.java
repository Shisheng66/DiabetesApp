package com.diabetes.health.controller;

import com.diabetes.health.dto.DashboardDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 首页今日概览（需登录）
 * GET /api/dashboard/today
 */
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/today")
    public DashboardDto.TodayResponse today(@AuthenticationPrincipal CurrentUser user) {
        return dashboardService.today(user);
    }
}
