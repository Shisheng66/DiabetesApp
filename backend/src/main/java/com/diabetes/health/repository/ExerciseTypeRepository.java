package com.diabetes.health.repository;

import com.diabetes.health.entity.ExerciseType;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ExerciseTypeRepository extends JpaRepository<ExerciseType, Long> {

    Optional<ExerciseType> findByCode(String code);

    @Cacheable("exerciseTypes")
    @Override
    List<ExerciseType> findAll();
}
