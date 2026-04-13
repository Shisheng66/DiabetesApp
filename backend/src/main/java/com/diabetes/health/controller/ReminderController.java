package com.diabetes.health.controller;

import com.diabetes.health.dto.ReminderDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.ReminderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 健康提醒（需登录）
 * POST   /api/reminders                新增提醒
 * GET    /api/reminders                提醒列表
 * PUT    /api/reminders/{id}           更新提醒
 * DELETE /api/reminders/{id}           删除提醒
 * POST   /api/push/register-token     注册推送 token（APP 启动时上报）
 */
@RestController
@RequiredArgsConstructor
public class ReminderController {

    private final ReminderService reminderService;

    @PostMapping("/api/reminders")
    public ReminderDto.ReminderResponse create(@AuthenticationPrincipal CurrentUser user,
                                               @Valid @RequestBody ReminderDto.CreateReminderRequest request) {
        return reminderService.create(user, request);
    }

    @GetMapping("/api/reminders")
    public ReminderDto.ListResponse list(@AuthenticationPrincipal CurrentUser user) {
        return ReminderDto.ListResponse.of(reminderService.list(user));
    }

    @PutMapping("/api/reminders/{id}")
    public ReminderDto.ReminderResponse update(@AuthenticationPrincipal CurrentUser user,
                                                @PathVariable Long id,
                                                @RequestBody ReminderDto.UpdateReminderRequest request) {
        return reminderService.update(user, id, request);
    }

    @DeleteMapping("/api/reminders/{id}")
    public void delete(@AuthenticationPrincipal CurrentUser user, @PathVariable Long id) {
        reminderService.delete(user, id);
    }

    @PostMapping("/api/push/register-token")
    public void registerPushToken(@AuthenticationPrincipal CurrentUser user,
                                   @Valid @RequestBody ReminderDto.RegisterPushRequest request) {
        reminderService.registerPushToken(user, request);
    }
}
