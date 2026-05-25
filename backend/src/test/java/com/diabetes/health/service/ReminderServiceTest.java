package com.diabetes.health.service;

import com.diabetes.health.dto.ReminderDto;
import com.diabetes.health.entity.HealthReminder;
import com.diabetes.health.entity.UserPushToken;
import com.diabetes.health.repository.HealthReminderLogRepository;
import com.diabetes.health.repository.HealthReminderRepository;
import com.diabetes.health.repository.UserPushTokenRepository;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReminderServiceTest {

    @Mock private HealthReminderRepository healthReminderRepository;
    @Mock private HealthReminderLogRepository healthReminderLogRepository;
    @Mock private UserPushTokenRepository userPushTokenRepository;
    @InjectMocks private ReminderService reminderService;

    private CurrentUser currentUser() {
        return new CurrentUser(1L, "13800138000", "PATIENT");
    }

    @Test
    void create_setsDefaults() {
        when(healthReminderRepository.save(any())).thenAnswer(inv -> {
            HealthReminder r = inv.getArgument(0);
            r.setId(10L);
            return r;
        });

        ReminderDto.CreateReminderRequest req = new ReminderDto.CreateReminderRequest();
        req.setType("GLUCOSE_TEST");
        req.setTimeOfDay(LocalTime.of(8, 0));

        var result = reminderService.create(currentUser(), req);
        assertThat(result.getId()).isEqualTo(10L);
        assertThat(result.getTimeOfDay()).isEqualTo(LocalTime.of(8, 0));
        verify(healthReminderRepository).save(argThat(r ->
                r.getType() == HealthReminder.ReminderType.GLUCOSE_TEST
                        && r.getRepeatType() == HealthReminder.RepeatType.DAILY
                        && Boolean.TRUE.equals(r.getEnabled())));
    }

    @Test
    void create_chineseLabel_parsesCorrectly() {
        when(healthReminderRepository.save(any())).thenAnswer(inv -> {
            HealthReminder r = inv.getArgument(0);
            r.setId(11L);
            return r;
        });

        ReminderDto.CreateReminderRequest req = new ReminderDto.CreateReminderRequest();
        req.setType("用药提醒");
        req.setTimeOfDay(LocalTime.of(9, 0));
        req.setRepeatType("每天");

        var result = reminderService.create(currentUser(), req);
        verify(healthReminderRepository).save(argThat(r ->
                r.getType() == HealthReminder.ReminderType.MEDICINE
                        && r.getRepeatType() == HealthReminder.RepeatType.DAILY));
    }

    @Test
    void list_returnsAllReminders() {
        HealthReminder r1 = HealthReminder.builder()
                .id(1L).userId(1L).type(HealthReminder.ReminderType.GLUCOSE_TEST)
                .timeOfDay(LocalTime.of(8, 0)).enabled(true).build();
        HealthReminder r2 = HealthReminder.builder()
                .id(2L).userId(1L).type(HealthReminder.ReminderType.MEDICINE)
                .timeOfDay(LocalTime.of(20, 0)).enabled(true).build();

        when(healthReminderRepository.findByUserIdOrderByTimeOfDayAsc(1L)).thenReturn(List.of(r1, r2));

        var result = reminderService.list(currentUser());
        assertThat(result).hasSize(2);
    }

    @Test
    void update_notFound_throws404() {
        when(healthReminderRepository.findById(99L)).thenReturn(Optional.empty());
        ReminderDto.UpdateReminderRequest req = new ReminderDto.UpdateReminderRequest();
        req.setEnabled(false);

        assertThatThrownBy(() -> reminderService.update(currentUser(), 99L, req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void update_notOwned_throws403() {
        HealthReminder reminder = HealthReminder.builder()
                .id(1L).userId(999L).type(HealthReminder.ReminderType.GLUCOSE_TEST).build();
        when(healthReminderRepository.findById(1L)).thenReturn(Optional.of(reminder));

        ReminderDto.UpdateReminderRequest req = new ReminderDto.UpdateReminderRequest();
        req.setEnabled(false);

        assertThatThrownBy(() -> reminderService.update(currentUser(), 1L, req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void update_owned_succeeds() {
        HealthReminder reminder = HealthReminder.builder()
                .id(1L).userId(1L).type(HealthReminder.ReminderType.GLUCOSE_TEST)
                .timeOfDay(LocalTime.of(8, 0)).repeatType(HealthReminder.RepeatType.DAILY)
                .enabled(true).build();
        when(healthReminderRepository.findById(1L)).thenReturn(Optional.of(reminder));
        when(healthReminderRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ReminderDto.UpdateReminderRequest req = new ReminderDto.UpdateReminderRequest();
        req.setEnabled(false);
        req.setRemark("关闭提醒");

        var result = reminderService.update(currentUser(), 1L, req);
        assertThat(result.getEnabled()).isFalse();
        verify(healthReminderRepository).save(argThat(r -> Boolean.FALSE.equals(r.getEnabled())));
    }

    @Test
    void delete_notFound_throws404() {
        when(healthReminderRepository.findById(99L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> reminderService.delete(currentUser(), 99L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void delete_notOwned_throws403() {
        HealthReminder reminder = HealthReminder.builder()
                .id(1L).userId(999L).type(HealthReminder.ReminderType.DIET).build();
        when(healthReminderRepository.findById(1L)).thenReturn(Optional.of(reminder));

        assertThatThrownBy(() -> reminderService.delete(currentUser(), 1L))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void delete_owned_deletes() {
        HealthReminder reminder = HealthReminder.builder()
                .id(1L).userId(1L).type(HealthReminder.ReminderType.DIET).build();
        when(healthReminderRepository.findById(1L)).thenReturn(Optional.of(reminder));

        reminderService.delete(currentUser(), 1L);
        verify(healthReminderRepository).delete(reminder);
    }

    @Test
    void registerPushToken_newToken_creates() {
        when(userPushTokenRepository.findByUserIdAndPushToken(1L, "abc123")).thenReturn(Optional.empty());
        when(userPushTokenRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ReminderDto.RegisterPushRequest req = new ReminderDto.RegisterPushRequest();
        req.setPushToken("abc123");
        req.setDeviceType("ANDROID");

        reminderService.registerPushToken(currentUser(), req);
        verify(userPushTokenRepository).save(argThat(t ->
                "abc123".equals(t.getPushToken()) && "ANDROID".equals(t.getDeviceType())));
    }

    @Test
    void registerPushToken_existingToken_updates() {
        UserPushToken existing = UserPushToken.builder()
                .id(1L).userId(1L).pushToken("abc123").deviceType("IOS").build();
        when(userPushTokenRepository.findByUserIdAndPushToken(1L, "abc123")).thenReturn(Optional.of(existing));
        when(userPushTokenRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ReminderDto.RegisterPushRequest req = new ReminderDto.RegisterPushRequest();
        req.setPushToken("abc123");
        req.setDeviceType("ANDROID");

        reminderService.registerPushToken(currentUser(), req);
        verify(userPushTokenRepository).save(argThat(t ->
                "ANDROID".equals(t.getDeviceType()) && t.getId().equals(1L)));
    }

    @Test
    void create_invalidType_throws400() {
        ReminderDto.CreateReminderRequest req = new ReminderDto.CreateReminderRequest();
        req.setType("INVALID_TYPE");
        req.setTimeOfDay(LocalTime.of(8, 0));

        assertThatThrownBy(() -> reminderService.create(currentUser(), req))
                .isInstanceOf(ResponseStatusException.class);
    }
}
