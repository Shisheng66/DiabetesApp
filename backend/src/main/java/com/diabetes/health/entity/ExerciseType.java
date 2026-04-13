package com.diabetes.health.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * 运动类型字典表
 */
@Entity
@Table(name = "exercise_type")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExerciseType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 20)
    private String code;  // WALK, RUN, RIDE, SWIM

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "met_value", precision = 5, scale = 2)
    private java.math.BigDecimal metValue;  // 代谢当量，用于计算热量
}
