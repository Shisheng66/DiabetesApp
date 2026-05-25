package com.diabetes.health.controller;

import com.diabetes.health.dto.DoctorDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.DoctorService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/doctor")
@RequiredArgsConstructor
public class DoctorController {

    private final DoctorService doctorService;

    @GetMapping("/patients")
    public Page<DoctorDto.PatientSummary> patients(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return doctorService.patients(user, page, size);
    }

    @GetMapping("/alerts")
    public Page<DoctorDto.AlertResponse> alerts(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return doctorService.alerts(user, page, size);
    }

    @GetMapping("/patients/{patientId}/report")
    public DoctorDto.PatientReportResponse patientReport(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long patientId) {
        return doctorService.patientReport(user, patientId);
    }
}
