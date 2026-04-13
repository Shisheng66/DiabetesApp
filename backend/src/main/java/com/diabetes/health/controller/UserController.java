package com.diabetes.health.controller;

import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.dto.UserDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * 用户与健康档案（需登录）
 * GET  /api/users/me              当前用户信息
 * PUT  /api/users/me              修改昵称、头像
 * GET  /api/users/me/health-profile  健康档案
 * PUT  /api/users/me/health-profile  更新健康档案
 * PUT  /api/users/me/password      修改密码
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public AuthDto.UserInfo me(@AuthenticationPrincipal CurrentUser user) {
        return userService.getMe(user);
    }

    @PutMapping("/me")
    public void updateMe(@AuthenticationPrincipal CurrentUser user,
                        @RequestBody UserDto.UpdateMeRequest request) {
        userService.updateMe(user, request);
    }

    @GetMapping("/me/health-profile")
    public UserDto.HealthProfileResponse getHealthProfile(@AuthenticationPrincipal CurrentUser user) {
        return userService.getHealthProfile(user);
    }

    @PutMapping("/me/health-profile")
    public UserDto.HealthProfileResponse updateHealthProfile(@AuthenticationPrincipal CurrentUser user,
                                                              @RequestBody UserDto.UpdateHealthProfileRequest request) {
        return userService.updateHealthProfile(user, request);
    }

    @PutMapping("/me/password")
    public void changePassword(@AuthenticationPrincipal CurrentUser user,
                               @Valid @RequestBody UserDto.ChangePasswordRequest request) {
        userService.changePassword(user, request);
    }
}
