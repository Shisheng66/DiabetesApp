package com.diabetes.health.controller;

import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserService userService;

    @GetMapping("/me")
    public AuthDto.AdminUserInfo me(@AuthenticationPrincipal CurrentUser user) {
        return userService.getAdminMe(user);
    }
}
