package com.diabetes.health.repository;

import com.diabetes.health.entity.DoctorPatientAccess;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DoctorPatientAccessRepository extends JpaRepository<DoctorPatientAccess, Long> {

    Optional<DoctorPatientAccess> findByDoctorIdAndPatientId(Long doctorId, Long patientId);

    boolean existsByDoctorIdAndPatientIdAndStatus(
            Long doctorId,
            Long patientId,
            DoctorPatientAccess.AccessStatus status
    );

    Page<DoctorPatientAccess> findByDoctorIdAndStatusOrderByGrantedAtDesc(
            Long doctorId,
            DoctorPatientAccess.AccessStatus status,
            Pageable pageable
    );

    List<DoctorPatientAccess> findByPatientIdOrderByGrantedAtDesc(Long patientId);

    List<DoctorPatientAccess> findByDoctorIdAndStatus(
            Long doctorId,
            DoctorPatientAccess.AccessStatus status
    );
}
