package com.diabetes.health.repository;

import com.diabetes.health.entity.ExerciseType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ExerciseTypeRepository extends JpaRepository<ExerciseType, Long> {

    Optional<ExerciseType> findByCode(String code);
}
