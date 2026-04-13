package com.diabetes.health.service;

import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.dto.UserDto;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserAccountRepository userAccountRepository;
    private final UserHealthProfileRepository healthProfileRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthDto.UserInfo getMe(CurrentUser currentUser) {
        UserAccount account = userAccountRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
        UserHealthProfile profile = healthProfileRepository.findByUserId(account.getId()).orElse(null);

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

    @Transactional
    public void updateMe(CurrentUser currentUser, UserDto.UpdateMeRequest req) {
        UserHealthProfile profile = healthProfileRepository.findByUserId(currentUser.getId()).orElseGet(() -> UserHealthProfile.builder()
                .userId(currentUser.getId())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build());

        if (req.getNickname() != null) {
            profile.setNickname(req.getNickname());
        }
        if (req.getAvatarUrl() != null) {
            profile.setAvatarUrl(req.getAvatarUrl());
        }
        healthProfileRepository.save(profile);
    }

    public UserDto.HealthProfileResponse getHealthProfile(CurrentUser currentUser) {
        return healthProfileRepository.findByUserId(currentUser.getId())
                .map(UserDto.HealthProfileResponse::from)
                .orElseGet(() -> {
                    UserDto.HealthProfileResponse response = new UserDto.HealthProfileResponse();
                    response.setUserId(currentUser.getId());
                    return response;
                });
    }

    @Transactional
    public UserDto.HealthProfileResponse updateHealthProfile(CurrentUser currentUser, UserDto.UpdateHealthProfileRequest req) {
        UserHealthProfile profile = healthProfileRepository.findByUserId(currentUser.getId()).orElseGet(() -> UserHealthProfile.builder()
                .userId(currentUser.getId())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build());

        if (req.getNickname() != null) profile.setNickname(req.getNickname());
        if (req.getAvatarUrl() != null) profile.setAvatarUrl(req.getAvatarUrl());
        if (req.getGender() != null) {
            try {
                profile.setGender(UserHealthProfile.Gender.valueOf(req.getGender()));
            } catch (IllegalArgumentException ignored) {
            }
        }
        if (req.getBirthDate() != null) profile.setBirthDate(req.getBirthDate());
        if (req.getHeightCm() != null) profile.setHeightCm(req.getHeightCm());
        if (req.getWeightKg() != null) profile.setWeightKg(req.getWeightKg());
        if (req.getDiabetesType() != null) {
            try {
                profile.setDiabetesType(UserHealthProfile.DiabetesType.valueOf(req.getDiabetesType()));
            } catch (IllegalArgumentException ignored) {
            }
        }
        if (req.getDiagnosisDate() != null) profile.setDiagnosisDate(req.getDiagnosisDate());
        if (req.getMedicationStatus() != null) profile.setMedicationStatus(req.getMedicationStatus());
        if (req.getTargetFbgMin() != null) profile.setTargetFbgMin(req.getTargetFbgMin());
        if (req.getTargetFbgMax() != null) profile.setTargetFbgMax(req.getTargetFbgMax());
        if (req.getTargetPbgMin() != null) profile.setTargetPbgMin(req.getTargetPbgMin());
        if (req.getTargetPbgMax() != null) profile.setTargetPbgMax(req.getTargetPbgMax());
        if (req.getRemark() != null) profile.setRemark(req.getRemark());

        return UserDto.HealthProfileResponse.from(healthProfileRepository.save(profile));
    }

    @Transactional
    public void changePassword(CurrentUser currentUser, UserDto.ChangePasswordRequest req) {
        UserAccount account = userAccountRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
        if (!passwordEncoder.matches(req.getOldPassword(), account.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "原密码错误");
        }
        account.setPasswordHash(passwordEncoder.encode(req.getNewPassword()));
        account.setUpdatedAt(Instant.now());
        userAccountRepository.save(account);
    }
}
