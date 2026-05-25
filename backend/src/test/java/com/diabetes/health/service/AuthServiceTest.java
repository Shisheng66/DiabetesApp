package com.diabetes.health.service;

import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.TokenBlacklistService;
import com.diabetes.health.util.JwtUtil;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private UserAccountRepository userAccountRepository;
    @Mock private UserHealthProfileRepository healthProfileRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtUtil jwtUtil;
    @Mock private AuthVerificationService authVerificationService;
    @Mock private TokenBlacklistService tokenBlacklistService;

    @InjectMocks private AuthService authService;

    @Test
    void register_shouldHardcodeRoleToPatient() {
        // Arrange
        AuthDto.RegisterRequest req = new AuthDto.RegisterRequest();
        req.setPhone("13800138000");
        req.setPassword("password123");
        req.setSmsCode("123456");

        when(userAccountRepository.existsByPhone("13800138000")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("encoded");
        when(userAccountRepository.save(any(UserAccount.class))).thenAnswer(inv -> {
            UserAccount acc = inv.getArgument(0);
            acc.setId(1L);
            return acc;
        });
        when(jwtUtil.generate(eq(1L))).thenReturn("token");

        // Act
        AuthDto.LoginResponse response = authService.register(req);

        // Assert
        ArgumentCaptor<UserAccount> captor = ArgumentCaptor.forClass(UserAccount.class);
        verify(userAccountRepository).save(captor.capture());
        assertThat(captor.getValue().getRole()).isEqualTo(UserAccount.Role.PATIENT);
        assertThat(response.getAccessToken()).isEqualTo("token");
    }

    @Test
    void register_shouldRejectDuplicatePhone() {
        AuthDto.RegisterRequest req = new AuthDto.RegisterRequest();
        req.setPhone("13800138000");
        req.setPassword("password123");
        req.setSmsCode("123456");

        when(userAccountRepository.existsByPhone("13800138000")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(req))
            .isInstanceOf(ResponseStatusException.class)
            .hasMessageContaining("已注册");
    }

    @Test
    void login_shouldUpdateLastLoginAt() {
        AuthDto.LoginRequest req = new AuthDto.LoginRequest();
        req.setPhone("13800138000");
        req.setPassword("password123");
        req.setLoginType(AuthDto.LoginType.PASSWORD);

        UserAccount account = UserAccount.builder()
            .id(1L).phone("13800138000")
            .passwordHash("encoded")
            .role(UserAccount.Role.PATIENT)
            .status(UserAccount.AccountStatus.NORMAL)
            .build();

        when(userAccountRepository.findByPhone("13800138000")).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("password123", "encoded")).thenReturn(true);
        when(userAccountRepository.save(any(UserAccount.class))).thenAnswer(inv -> inv.getArgument(0));
        when(jwtUtil.generate(anyLong())).thenReturn("token");

        authService.login(req);

        verify(userAccountRepository).save(argThat(a -> a.getLastLoginAt() != null));
        verify(authVerificationService, never()).verifySmsCode(anyString(), any(), anyString());
    }

    @Test
    void login_shouldRejectInvalidSmsCodeOnlyForSmsLogin() {
        AuthDto.LoginRequest req = new AuthDto.LoginRequest();
        req.setPhone("13800138000");
        req.setSmsCode("");
        req.setLoginType(AuthDto.LoginType.SMS);

        UserAccount account = UserAccount.builder()
            .id(1L).phone("13800138000")
            .passwordHash("encoded")
            .role(UserAccount.Role.PATIENT)
            .status(UserAccount.AccountStatus.NORMAL)
            .build();

        when(userAccountRepository.findByPhone("13800138000")).thenReturn(Optional.of(account));

        assertThatThrownBy(() -> authService.login(req))
            .isInstanceOf(ResponseStatusException.class)
            .hasMessageContaining("短信验证码格式不正确");
    }
}
