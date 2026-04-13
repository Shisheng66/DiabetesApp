package com.diabetes.health.config;

import com.diabetes.health.entity.ExerciseType;
import com.diabetes.health.repository.ExerciseTypeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * 首次启动时若运动类型表为空，插入步行/跑步/骑行/游泳等类型。
 */
@Component
@RequiredArgsConstructor
public class ExerciseDataLoader implements ApplicationRunner {

    private final ExerciseTypeRepository exerciseTypeRepository;

    @Override
    public void run(ApplicationArguments args) {
        if (exerciseTypeRepository.count() > 0) return;
        exerciseTypeRepository.save(ExerciseType.builder().code("WALK").name("步行").metValue(new BigDecimal("3.0")).build());
        exerciseTypeRepository.save(ExerciseType.builder().code("RUN").name("跑步").metValue(new BigDecimal("9.8")).build());
        exerciseTypeRepository.save(ExerciseType.builder().code("RIDE").name("骑行").metValue(new BigDecimal("7.5")).build());
        exerciseTypeRepository.save(ExerciseType.builder().code("SWIM").name("游泳").metValue(new BigDecimal("8.0")).build());
    }
}
