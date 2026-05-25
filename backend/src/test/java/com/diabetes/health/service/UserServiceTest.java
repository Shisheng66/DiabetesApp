package com.diabetes.health.service;

import com.diabetes.health.dto.UserDto;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
class UserServiceTest {

    @Mock private UserAccountRepository userAccountRepository;
    @Mock private UserHealthProfileRepository healthProfileRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @InjectMocks private UserService userService;

    private CurrentUser currentUser() {
        return new CurrentUser(1L, "13800138000", "PATIENT");
    }

    @Test
    void getMe_returnsUserInfo() {
        UserAccount account = UserAccount.builder()
            .id(1L).phone("13800138000").role(UserAccount.Role.PATIENT).build();
        UserHealthProfile profile = UserHealthProfile.builder()
            .userId(1L).nickname("测试用户").build();

        when(userAccountRepository.findById(1L)).thenReturn(Optional.of(account));
        when(healthProfileRepository.findByUserId(1L)).thenReturn(Optional.of(profile));

        var result = userService.getMe(currentUser());
        assertThat(result.getPhone()).isEqualTo("13800138000");
        assertThat(result.getNickname()).isEqualTo("测试用户");
    }

    @Test
    void getMe_userNotFound_throws404() {
        when(userAccountRepository.findById(1L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> userService.getMe(currentUser()))
            .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void updateMe_setsNickname() {
        UserHealthProfile profile = UserHealthProfile.builder().userId(1L).build();
        when(healthProfileRepository.findByUserId(1L)).thenReturn(Optional.of(profile));
        when(healthProfileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UserDto.UpdateMeRequest req = new UserDto.UpdateMeRequest();
        req.setNickname("新昵称");
        userService.updateMe(currentUser(), req);

        verify(healthProfileRepository).save(argThat(p -> "新昵称".equals(p.getNickname())));
    }

    @Test
    void changePassword_wrongOldPassword_throws400() {
        UserAccount account = UserAccount.builder()
            .id(1L).passwordHash("encoded").build();
        when(userAccountRepository.findById(1L)).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("wrong", "encoded")).thenReturn(false);

        UserDto.ChangePasswordRequest req = new UserDto.ChangePasswordRequest();
        req.setOldPassword("wrong");
        req.setNewPassword("NewPass123");

        assertThatThrownBy(() -> userService.changePassword(currentUser(), req))
            .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void changePassword_correctPassword_succeeds() {
        UserAccount account = UserAccount.builder()
            .id(1L).passwordHash("encoded").build();
        when(userAccountRepository.findById(1L)).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("OldPass1", "encoded")).thenReturn(true);
        when(passwordEncoder.encode("NewPass123")).thenReturn("newEncoded");
        when(userAccountRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UserDto.ChangePasswordRequest req = new UserDto.ChangePasswordRequest();
        req.setOldPassword("OldPass1");
        req.setNewPassword("NewPass123");

        userService.changePassword(currentUser(), req);
        verify(userAccountRepository).save(argThat(a -> "newEncoded".equals(a.getPasswordHash())));
    }
}
