package com.diabetes.health.service;

import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.dto.UserDto;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserAccountRepository userAccountRepository;
    private final UserHealthProfileRepository healthProfileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthVerificationService authVerificationService;

    public AuthDto.CaptchaResponse createCaptcha() {
        return authVerificationService.createCaptcha();
    }

    public AuthDto.SendSmsCodeResponse sendSmsCode(AuthDto.SendSmsCodeRequest request) {
        return authVerificationService.sendSmsCode(request);
    }

    @Transactional
    public AuthDto.LoginResponse register(AuthDto.RegisterRequest req) {
        if (userAccountRepository.existsByPhone(req.getPhone())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "该手机号已注册");
        }
        authVerificationService.verifySmsCode(req.getPhone(), AuthDto.SmsScene.REGISTER, req.getSmsCode());
        UserAccount.AccountStatus status = UserAccount.AccountStatus.NORMAL;
        UserAccount.Role role;
        try {
            role = UserAccount.Role.valueOf(req.getRole() != null ? req.getRole().toUpperCase() : "PATIENT");
        } catch (IllegalArgumentException e) {
            role = UserAccount.Role.PATIENT;
        }
        UserAccount account = UserAccount.builder()
                .phone(req.getPhone())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .role(role)
                .status(status)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
        account = userAccountRepository.save(account);

        UserHealthProfile profile = UserHealthProfile.builder()
                .userId(account.getId())
                .nickname("用户" + req.getPhone().substring(7))
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
        healthProfileRepository.save(profile);

        String token = jwtUtil.generate(account.getId(), account.getPhone(), account.getRole().name());
        AuthDto.UserInfo info = toUserInfo(account, profile);
        return new AuthDto.LoginResponse(token, info);
    }

    public AuthDto.LoginResponse login(AuthDto.LoginRequest req) {
        AuthDto.LoginType loginType = req.getLoginType() == null ? AuthDto.LoginType.PASSWORD : req.getLoginType();
        UserAccount account = userAccountRepository.findByPhone(req.getPhone())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "账号信息不正确"));
        if (account.getStatus() != UserAccount.AccountStatus.NORMAL) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "账号已禁用");
        }
        if (loginType == AuthDto.LoginType.SMS) {
            authVerificationService.verifySmsCode(req.getPhone(), AuthDto.SmsScene.LOGIN, req.getSmsCode());
        } else {
            if (req.getPassword() == null || req.getPassword().isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请输入登录密码");
            }
            if (!passwordEncoder.matches(req.getPassword(), account.getPasswordHash())) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "手机号或密码错误");
            }
        }
        account.setLastLoginAt(Instant.now());
        userAccountRepository.save(account);

        UserHealthProfile profile = healthProfileRepository.findByUserId(account.getId()).orElse(null);
        String token = jwtUtil.generate(account.getId(), account.getPhone(), account.getRole().name());
        AuthDto.UserInfo info = toUserInfo(account, profile);
        return new AuthDto.LoginResponse(token, info);
    }

    private AuthDto.UserInfo toUserInfo(UserAccount account, UserHealthProfile profile) {
        AuthDto.UserInfo info = new AuthDto.UserInfo();
        info.setId(account.getId());
        info.setPhone(account.getPhone());
        info.setRole(account.getRole().name());
        if (profile != null) {
            info.setNickname(profile.getNickname());
            info.setAvatarUrl(profile.getAvatarUrl());
            info.setHealthProfile(UserDto.HealthProfileResponse.from(profile));
        }
        return info;
    }
}
