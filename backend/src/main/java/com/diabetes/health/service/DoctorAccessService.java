package com.diabetes.health.service;

import com.diabetes.health.dto.DoctorAccessDto;
import com.diabetes.health.entity.DoctorPatientAccess;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.DoctorPatientAccessRepository;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DoctorAccessService {

    private final DoctorPatientAccessRepository accessRepository;
    private final UserAccountRepository userAccountRepository;
    private final UserHealthProfileRepository profileRepository;

    @Transactional
    public DoctorAccessDto.AccessResponse grant(CurrentUser patient, DoctorAccessDto.GrantRequest request) {
        requirePatient(patient);
        UserAccount doctor = userAccountRepository.findByPhone(request.getDoctorPhone().trim())
                .filter(account -> account.getRole() == UserAccount.Role.DOCTOR)
                .filter(account -> account.getStatus() == UserAccount.AccountStatus.NORMAL)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "未找到可授权的医生账号"));

        DoctorPatientAccess access = accessRepository.findByDoctorIdAndPatientId(doctor.getId(), patient.getId())
                .orElseGet(() -> DoctorPatientAccess.builder()
                        .doctorId(doctor.getId())
                        .patientId(patient.getId())
                        .build());
        access.setStatus(DoctorPatientAccess.AccessStatus.ACTIVE);
        access.setGrantedAt(Instant.now());
        access.setRevokedAt(null);
        return toResponse(accessRepository.save(access), doctor, null);
    }

    @Transactional
    public void revoke(CurrentUser patient, Long doctorId) {
        requirePatient(patient);
        DoctorPatientAccess access = accessRepository.findByDoctorIdAndPatientId(doctorId, patient.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "授权记录不存在"));
        access.setStatus(DoctorPatientAccess.AccessStatus.REVOKED);
        access.setRevokedAt(Instant.now());
        accessRepository.save(access);
    }

    public List<DoctorAccessDto.AccessResponse> listMine(CurrentUser patient) {
        requirePatient(patient);
        List<DoctorPatientAccess> accesses = accessRepository.findByPatientIdOrderByGrantedAtDesc(patient.getId());
        Map<Long, UserAccount> doctors = userAccountRepository.findAllById(
                        accesses.stream().map(DoctorPatientAccess::getDoctorId).toList()
                ).stream().collect(Collectors.toMap(UserAccount::getId, account -> account));
        Map<Long, UserHealthProfile> profiles = profileRepository.findAllByUserIdIn(doctors.keySet().stream().toList())
                .stream().collect(Collectors.toMap(UserHealthProfile::getUserId, profile -> profile));
        return accesses.stream()
                .map(access -> toResponse(access, doctors.get(access.getDoctorId()), profiles.get(access.getDoctorId())))
                .toList();
    }

    private DoctorAccessDto.AccessResponse toResponse(
            DoctorPatientAccess access,
            UserAccount doctor,
            UserHealthProfile profile
    ) {
        DoctorAccessDto.AccessResponse response = new DoctorAccessDto.AccessResponse();
        response.setDoctorId(access.getDoctorId());
        response.setDoctorName(profile != null && profile.getNickname() != null && !profile.getNickname().isBlank()
                ? profile.getNickname() : "医生");
        response.setDoctorPhoneMasked(doctor == null ? "" : maskPhone(doctor.getPhone()));
        response.setStatus(access.getStatus() == DoctorPatientAccess.AccessStatus.ACTIVE ? "已授权" : "已取消");
        response.setGrantedAt(access.getGrantedAt());
        response.setRevokedAt(access.getRevokedAt());
        return response;
    }

    private void requirePatient(CurrentUser user) {
        if (user == null || !"PATIENT".equals(user.getRole())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "仅患者本人可以管理医生授权");
        }
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) return "";
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
}
