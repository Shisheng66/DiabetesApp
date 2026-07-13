package com.diabetes.health.controller;

import com.diabetes.health.dto.DoctorAccessDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.DoctorAccessService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/doctor-access")
@RequiredArgsConstructor
public class DoctorAccessController {

    private final DoctorAccessService doctorAccessService;

    @GetMapping
    public List<DoctorAccessDto.AccessResponse> listMine(@AuthenticationPrincipal CurrentUser user) {
        return doctorAccessService.listMine(user);
    }

    @PostMapping
    public DoctorAccessDto.AccessResponse grant(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody DoctorAccessDto.GrantRequest request
    ) {
        return doctorAccessService.grant(user, request);
    }

    @DeleteMapping("/{doctorId}")
    public void revoke(@AuthenticationPrincipal CurrentUser user, @PathVariable Long doctorId) {
        doctorAccessService.revoke(user, doctorId);
    }
}
