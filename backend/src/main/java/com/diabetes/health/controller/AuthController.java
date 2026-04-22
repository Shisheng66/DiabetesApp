package com.diabetes.health.controller;

import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.service.AuthService;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 认证接口（无需登录）
 * 注册：POST /api/auth/register
 * 登录：POST /api/auth/login
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public AuthDto.LoginResponse register(@Valid @RequestBody AuthDto.RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public AuthDto.LoginResponse login(@Valid @RequestBody AuthDto.LoginRequest request) {
        return authService.login(request);
    }

    @GetMapping("/captcha")
    public AuthDto.CaptchaResponse captcha() {
        return authService.createCaptcha();
    }

    @PostMapping("/sms/send")
    public AuthDto.SendSmsCodeResponse sendSmsCode(@Valid @RequestBody AuthDto.SendSmsCodeRequest request) {
        return authService.sendSmsCode(request);
    }

    @PostMapping("/logout")
    public void logout(HttpServletRequest request) {
        authService.logout(request.getHeader("Authorization"));
    }
}
