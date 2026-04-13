package com.diabetes.health.service;

import com.diabetes.health.dto.BloodGlucoseDto;
import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.BloodGlucoseRecordRepository;
import com.diabetes.health.repository.GlucoseAbnormalEventRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BloodGlucoseServiceTest {

    @Mock
    private BloodGlucoseRecordRepository recordRepository;

    @Mock
    private GlucoseAbnormalEventRepository abnormalEventRepository;

    @Mock
    private UserHealthProfileRepository healthProfileRepository;

    @InjectMocks
    private BloodGlucoseService bloodGlucoseService;

    @Test
    void createUsesPostMealFallbackTargetsWhenProfileTargetsMissing() {
        CurrentUser user = new CurrentUser(1L, "13800138000", "USER");
        BloodGlucoseDto.CreateRecordRequest request = new BloodGlucoseDto.CreateRecordRequest();
        request.setMeasureType("POST_MEAL");
        request.setMeasureTime(Instant.parse("2026-04-13T12:00:00Z"));
        request.setValueMmolL(new BigDecimal("4.0"));

        UserHealthProfile profile = UserHealthProfile.builder()
                .userId(1L)
                .targetFbgMin(new BigDecimal("3.9"))
                .targetFbgMax(new BigDecimal("6.1"))
                .targetPbgMin(null)
                .targetPbgMax(null)
                .build();

        when(healthProfileRepository.findByUserId(1L)).thenReturn(Optional.of(profile));
        when(recordRepository.save(any(BloodGlucoseRecord.class))).thenAnswer(invocation -> {
            BloodGlucoseRecord saved = invocation.getArgument(0);
            saved.setId(99L);
            return saved;
        });

        BloodGlucoseDto.RecordResponse response = bloodGlucoseService.create(user, request);

        ArgumentCaptor<BloodGlucoseRecord> recordCaptor = ArgumentCaptor.forClass(BloodGlucoseRecord.class);
        verify(recordRepository).save(recordCaptor.capture());

        assertThat(recordCaptor.getValue().getAbnormalFlag()).isEqualTo(BloodGlucoseRecord.AbnormalFlag.LOW);
        assertThat(response.getAbnormalFlag()).isEqualTo(BloodGlucoseRecord.AbnormalFlag.LOW.name());
        verify(abnormalEventRepository).save(any());
    }
}
