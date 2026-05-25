package com.diabetes.health.service;

import com.diabetes.health.dto.ExerciseDto;
import com.diabetes.health.entity.DietRecord;
import com.diabetes.health.entity.ExerciseRecord;
import com.diabetes.health.entity.ExerciseType;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.DietRecordRepository;
import com.diabetes.health.repository.ExerciseRecordRepository;
import com.diabetes.health.repository.ExerciseTypeRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExerciseServiceTest {

    @Mock
    private ExerciseRecordRepository exerciseRecordRepository;

    @Mock
    private ExerciseTypeRepository exerciseTypeRepository;

    @Mock
    private DietRecordRepository dietRecordRepository;

    @Mock
    private UserHealthProfileRepository userHealthProfileRepository;

    @InjectMocks
    private ExerciseService exerciseService;

    @Test
    void getDailyRecommendationTreatsNullCaloriesAsZero() {
        CurrentUser user = new CurrentUser(1L, "13800138000", "USER");
        LocalDate date = LocalDate.of(2026, 4, 13);

        DietRecord breakfast = DietRecord.builder()
                .userId(1L)
                .recordDate(date)
                .calorieKcal(null)
                .build();
        DietRecord lunch = DietRecord.builder()
                .userId(1L)
                .recordDate(date)
                .calorieKcal(new BigDecimal("520"))
                .build();
        ExerciseRecord walk = ExerciseRecord.builder()
                .userId(1L)
                .startTime(Instant.parse("2026-04-13T09:00:00Z"))
                .calorieKcal(null)
                .build();
        ExerciseType type = ExerciseType.builder()
                .id(1L)
                .name("快走")
                .metValue(new BigDecimal("3.5"))
                .build();
        UserHealthProfile profile = UserHealthProfile.builder()
                .userId(1L)
                .weightKg(new BigDecimal("70"))
                .build();

        when(dietRecordRepository.findByUserIdAndRecordDateAndDeletedFalseOrderByRecordTimeDesc(1L, date))
                .thenReturn(List.of(breakfast, lunch));
        when(exerciseRecordRepository.findByUserIdAndStartTimeBetweenAndDeletedFalseOrderByStartTimeDesc(
                org.mockito.ArgumentMatchers.eq(1L),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any()))
                .thenReturn(List.of(walk));
        when(exerciseTypeRepository.findAll()).thenReturn(List.of(type));
        when(userHealthProfileRepository.findByUserId(1L)).thenReturn(Optional.of(profile));

        ExerciseDto.DailyRecommendationResponse response = exerciseService.getDailyRecommendation(user, date);

        assertThat(response.getTodayCalorieIntake()).isEqualByComparingTo("520.00");
        assertThat(response.getTodayCalorieBurned()).isEqualByComparingTo("0.00");
        assertThat(response.getSuggestions()).isNotEmpty();
        assertThat(response.getSummary()).isNotBlank();
    }
}
