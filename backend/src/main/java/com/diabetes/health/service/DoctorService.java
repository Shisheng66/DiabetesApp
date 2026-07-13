package com.diabetes.health.service;

import com.diabetes.health.dto.DoctorDto;
import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.entity.DoctorPatientAccess;
import com.diabetes.health.entity.GlucoseAbnormalEvent;
import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.BloodGlucoseRecordRepository;
import com.diabetes.health.repository.DoctorPatientAccessRepository;
import com.diabetes.health.repository.GlucoseAbnormalEventRepository;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.util.DisplayLabel;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DoctorService {

    private final UserAccountRepository userAccountRepository;
    private final UserHealthProfileRepository profileRepository;
    private final GlucoseAbnormalEventRepository abnormalEventRepository;
    private final BloodGlucoseRecordRepository glucoseRecordRepository;
    private final DoctorPatientAccessRepository doctorPatientAccessRepository;

    public Page<DoctorDto.PatientSummary> patients(CurrentUser doctor, int page, int size) {
        ensureDoctor(doctor);
        int safeSize = Math.min(Math.max(size, 1), 50);
        PageRequest pageable = PageRequest.of(Math.max(page, 0), safeSize);
        if (!isAdmin(doctor)) {
            Page<DoctorPatientAccess> accessPage = doctorPatientAccessRepository
                    .findByDoctorIdAndStatusOrderByGrantedAtDesc(
                            doctor.getId(),
                            DoctorPatientAccess.AccessStatus.ACTIVE,
                            pageable
                    );
            List<Long> patientIds = accessPage.getContent().stream()
                    .map(DoctorPatientAccess::getPatientId)
                    .toList();
            Map<Long, UserAccount> accounts = userAccountRepository.findAllById(patientIds).stream()
                    .filter(account -> account.getRole() == UserAccount.Role.PATIENT)
                    .filter(account -> account.getStatus() == UserAccount.AccountStatus.NORMAL)
                    .collect(Collectors.toMap(UserAccount::getId, account -> account));
            Map<Long, UserHealthProfile> profiles = profilesByUserIds(patientIds);
            List<DoctorDto.PatientSummary> content = patientIds.stream()
                    .map(accounts::get)
                    .filter(java.util.Objects::nonNull)
                    .map(account -> toPatientSummary(account, profiles.get(account.getId())))
                    .toList();
            return new PageImpl<>(content, pageable, accessPage.getTotalElements());
        }
        Page<UserAccount> accounts = userAccountRepository.findByRoleAndStatus(
                UserAccount.Role.PATIENT,
                UserAccount.AccountStatus.NORMAL,
                pageable
        );
        Map<Long, UserHealthProfile> profiles = profilesByUserIds(
                accounts.getContent().stream().map(UserAccount::getId).toList()
        );
        return accounts.map(account -> toPatientSummary(account, profiles.get(account.getId())));
    }

    public Page<DoctorDto.AlertResponse> alerts(CurrentUser doctor, int page, int size) {
        ensureDoctor(doctor);
        int safeSize = Math.min(Math.max(size, 1), 50);
        PageRequest pageable = PageRequest.of(Math.max(page, 0), safeSize);
        Page<GlucoseAbnormalEvent> events;
        if (isAdmin(doctor)) {
            events = abnormalEventRepository.findByHandledFalseOrderByCreatedAtDesc(pageable);
        } else {
            List<Long> patientIds = doctorPatientAccessRepository.findByDoctorIdAndStatus(
                            doctor.getId(),
                            DoctorPatientAccess.AccessStatus.ACTIVE
                    ).stream()
                    .map(DoctorPatientAccess::getPatientId)
                    .toList();
            if (patientIds.isEmpty()) {
                return Page.empty(pageable);
            }
            events = abnormalEventRepository.findByUserIdInAndHandledFalseOrderByCreatedAtDesc(patientIds, pageable);
        }
        Map<Long, UserHealthProfile> profiles = profilesByUserIds(
                events.getContent().stream().map(GlucoseAbnormalEvent::getUserId).distinct().toList()
        );
        return events.map(event -> toAlert(event, profiles.get(event.getUserId())));
    }

    public DoctorDto.PatientReportResponse patientReport(CurrentUser doctor, Long patientId) {
        ensureDoctor(doctor);
        if (!isAdmin(doctor) && !doctorPatientAccessRepository.existsByDoctorIdAndPatientIdAndStatus(
                doctor.getId(), patientId, DoctorPatientAccess.AccessStatus.ACTIVE)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "患者尚未授权该医生查看健康报告");
        }
        UserAccount patient = userAccountRepository.findById(patientId)
                .filter(account -> account.getRole() == UserAccount.Role.PATIENT)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "患者不存在"));
        UserHealthProfile profile = profileRepository.findByUserId(patient.getId()).orElse(null);
        Instant end = Instant.now().plus(1, ChronoUnit.DAYS);
        Instant start = Instant.now().minus(30, ChronoUnit.DAYS);
        DoctorDto.PatientReportResponse response = new DoctorDto.PatientReportResponse();
        response.setPatientId(patient.getId());
        response.setPatientName(displayName(profile, patient));
        response.setDiabetesType(profile == null ? "未填写" : DisplayLabel.diabetesType(profile.getDiabetesType()));
        response.setAbnormalCount(abnormalEventRepository.countByUserId(patient.getId()));
        response.setRecentGlucose(
                glucoseRecordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(patient.getId(), start, end)
                        .stream()
                        .limit(30)
                        .map(this::toPoint)
                        .toList()
        );
        return response;
    }

    private DoctorDto.PatientSummary toPatientSummary(UserAccount account, UserHealthProfile profile) {
        DoctorDto.PatientSummary r = new DoctorDto.PatientSummary();
        r.setPatientId(account.getId());
        r.setPhoneMasked(maskPhone(account.getPhone()));
        r.setNickname(displayName(profile, account));
        r.setDiabetesType(profile == null ? "未填写" : DisplayLabel.diabetesType(profile.getDiabetesType()));
        r.setLastLoginAt(account.getLastLoginAt());
        r.setAbnormalCount(abnormalEventRepository.countByUserId(account.getId()));
        return r;
    }

    private DoctorDto.AlertResponse toAlert(GlucoseAbnormalEvent event, UserHealthProfile profile) {
        DoctorDto.AlertResponse r = new DoctorDto.AlertResponse();
        r.setId(event.getId());
        r.setPatientId(event.getUserId());
        r.setPatientName(profile == null || profile.getNickname() == null ? "患者" + event.getUserId() : profile.getNickname());
        r.setType(event.getType() == GlucoseAbnormalEvent.EventType.HIGH ? "血糖偏高" : "血糖偏低");
        r.setLevel(event.getLevel());
        r.setHandled(event.getHandled());
        r.setCreatedAt(event.getCreatedAt());
        return r;
    }

    private DoctorDto.GlucosePoint toPoint(BloodGlucoseRecord record) {
        DoctorDto.GlucosePoint p = new DoctorDto.GlucosePoint();
        p.setMeasureTime(record.getMeasureTime());
        p.setMeasureType(DisplayLabel.measureType(record.getMeasureType()));
        p.setValueMmolL(record.getValueMmolL());
        p.setAbnormalFlag(DisplayLabel.abnormal(record.getAbnormalFlag()));
        return p;
    }

    private void ensureDoctor(CurrentUser user) {
        if (user == null || (!"DOCTOR".equals(user.getRole()) && !"ADMIN".equals(user.getRole()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "仅医生或管理员可访问医生工作台");
        }
    }

    private boolean isAdmin(CurrentUser user) {
        return user != null && "ADMIN".equals(user.getRole());
    }

    private Map<Long, UserHealthProfile> profilesByUserIds(List<Long> userIds) {
        if (userIds.isEmpty()) {
            return Map.of();
        }
        return profileRepository.findAllByUserIdIn(userIds).stream()
                .collect(Collectors.toMap(UserHealthProfile::getUserId, p -> p));
    }

    private String displayName(UserHealthProfile profile, UserAccount account) {
        if (profile != null && profile.getNickname() != null && !profile.getNickname().isBlank()) {
            return profile.getNickname();
        }
        return "患者" + account.getId();
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) return "未绑定";
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
}
