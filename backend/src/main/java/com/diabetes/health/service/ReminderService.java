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
        HealthReminder.ReminderType type = parseReminderType(req.getType());
        HealthReminder.RepeatType repeatType = parseRepeatType(req.getRepeatType(), HealthReminder.RepeatType.DAILY);
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
            reminder.setRepeatType(parseRepeatType(req.getRepeatType(), reminder.getRepeatType()));
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

    private HealthReminder.ReminderType parseReminderType(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase();
        switch (normalized) {
            case "血糖提醒" -> { return HealthReminder.ReminderType.GLUCOSE_TEST; }
            case "用药提醒" -> { return HealthReminder.ReminderType.MEDICINE; }
            case "运动提醒" -> { return HealthReminder.ReminderType.EXERCISE; }
            case "饮食提醒" -> { return HealthReminder.ReminderType.DIET; }
            default -> {
            }
        }
        try {
            return HealthReminder.ReminderType.valueOf(normalized);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "提醒类型选择不正确");
        }
    }

    private HealthReminder.RepeatType parseRepeatType(String value, HealthReminder.RepeatType fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        String normalized = value.trim().toUpperCase();
        switch (normalized) {
            case "每天" -> { return HealthReminder.RepeatType.DAILY; }
            case "工作日" -> { return HealthReminder.RepeatType.WORKDAY; }
            case "自定义" -> { return HealthReminder.RepeatType.CUSTOM; }
            default -> {
            }
        }
        try {
            return HealthReminder.RepeatType.valueOf(normalized);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "重复方式选择不正确");
        }
    }
}
