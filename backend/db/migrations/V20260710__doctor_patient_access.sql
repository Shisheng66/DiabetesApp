-- Run this migration in the production MySQL database before deploying the doctor authorization feature.
CREATE TABLE IF NOT EXISTS doctor_patient_access (
    id BIGINT NOT NULL AUTO_INCREMENT,
    doctor_id BIGINT NOT NULL,
    patient_id BIGINT NOT NULL,
    status VARCHAR(16) NOT NULL,
    granted_at TIMESTAMP(6) NOT NULL,
    revoked_at TIMESTAMP(6) NULL,
    updated_at TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_doctor_patient_access_doctor_patient UNIQUE (doctor_id, patient_id),
    INDEX idx_doctor_patient_access_doctor_status (doctor_id, status),
    INDEX idx_doctor_patient_access_patient_status (patient_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
