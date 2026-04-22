package com.diabetes.health.service;

import com.diabetes.health.dto.ReminderDto;
import com.diabetes.health.entity.HealthReminder;
import com.diabetes.health.entity.UserPushToken;
import com.diabetes.health.repository.HealthReminderLogRepository;
import com.diabetes.health.repository.HealthReminderRepository;
import com.diabetes.health.repository.UserPushTokenRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReminderService {

    private final HealthReminderRepository healthReminderRepository;
    private final HealthReminderLogRepository healthReminderLogRepository;
    private final UserPushTokenRepository userPushTokenRepository;

    @Transactional
    @CacheEvict(value = "dashboard", key = "#user.id")
    public ReminderDto.ReminderResponse create(CurrentUser user, ReminderDto.CreateReminderRequest req) {
        HealthReminder.ReminderType type;
        try {
            type = HealthReminder.ReminderType.valueOf(req.getType().toUpperCase());
        } catch (Exception e) {
            type = HealthReminder.ReminderType.MEDICINE;
        }
        HealthReminder.RepeatType repeatType = HealthReminder.RepeatType.DAILY;
        if (req.getRepeatType() != null && !req.getRepeatType().isBlank()) {
            try {
                repeatType = HealthReminder.RepeatType.valueOf(req.getRepeatType().toUpperCase());
            } catch (Exception ignored) {}
        }
        HealthReminder reminder = HealthReminder.builder()
                .userId(user.getId())
                .type(type)
                .timeOfDay(req.getTimeOfDay())
                .repeatType(repeatType)
                .enabled(req.getEnabled() != null ? req.getEnabled() : true)
                .remark(req.getRemark())
                .build();
        reminder = healthReminderRepository.save(reminder);
        return ReminderDto.ReminderResponse.from(reminder);
    }

    public List<ReminderDto.ReminderResponse> list(CurrentUser user) {
        return healthReminderRepository.findByUserIdOrderByTimeOfDayAsc(user.getId()).stream()
                .map(ReminderDto.ReminderResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    @CacheEvict(value = "dashboard", key = "#user.id")
    public ReminderDto.ReminderResponse update(CurrentUser user, Long id, ReminderDto.UpdateReminderRequest req) {
        HealthReminder reminder = healthReminderRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "提醒不存在"));
        if (!reminder.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权限");
        }
        if (req.getTimeOfDay() != null) reminder.setTimeOfDay(req.getTimeOfDay());
        if (req.getRepeatType() != null && !req.getRepeatType().isBlank()) {
            try {
                reminder.setRepeatType(HealthReminder.RepeatType.valueOf(req.getRepeatType().toUpperCase()));
            } catch (Exception ignored) {}
        }
        if (req.getEnabled() != null) reminder.setEnabled(req.getEnabled());
        if (req.getRemark() != null) reminder.setRemark(req.getRemark());
        reminder = healthReminderRepository.save(reminder);
        return ReminderDto.ReminderResponse.from(reminder);
    }

    @Transactional
    @CacheEvict(value = "dashboard", key = "#user.id")
    public void delete(CurrentUser user, Long id) {
        HealthReminder reminder = healthReminderRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "提醒不存在"));
        if (!reminder.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权限");
        }
        healthReminderRepository.delete(reminder);
    }

    @Transactional
    public void registerPushToken(CurrentUser user, ReminderDto.RegisterPushRequest req) {
        UserPushToken existing = userPushTokenRepository.findByUserIdAndPushToken(user.getId(), req.getPushToken()).orElse(null);
        if (existing != null) {
            existing.setDeviceType(req.getDeviceType());
            existing.touch();
            userPushTokenRepository.save(existing);
            return;
        }
        UserPushToken token = UserPushToken.builder()
                .userId(user.getId())
                .deviceType(req.getDeviceType() != null ? req.getDeviceType() : "ANDROID")
                .pushToken(req.getPushToken())
                .updatedAt(Instant.now())
                .build();
        userPushTokenRepository.save(token);
    }
}
