package com.diabetes.health.controller;

import com.diabetes.health.dto.ExerciseDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.ExerciseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/exercise")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseService exerciseService;

    @PostMapping("/records")
    public ExerciseDto.RecordResponse create(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody ExerciseDto.CreateRecordRequest request) {
        return exerciseService.create(user, request);
    }

    @GetMapping("/records")
    public List<ExerciseDto.RecordResponse> list(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return exerciseService.list(user, startDate, endDate, page, size);
    }

    @GetMapping("/summary/daily")
    public ExerciseDto.DailySummaryResponse dailySummary(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return exerciseService.getDailySummary(user, date);
    }

    @DeleteMapping("/records/{id}")
    public void delete(@AuthenticationPrincipal CurrentUser user, @PathVariable Long id) {
        exerciseService.delete(user, id);
    }

    @GetMapping("/types")
    public List<ExerciseDto.TypeResponse> listTypes() {
        return exerciseService.listExerciseTypes();
    }

    @GetMapping("/recommendation/daily")
    public ExerciseDto.DailyRecommendationResponse dailyRecommendation(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return exerciseService.getDailyRecommendation(user, date);
    }
}
