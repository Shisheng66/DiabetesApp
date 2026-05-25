package com.diabetes.health.repository;

import com.diabetes.health.entity.FoodNutrition;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodNutritionRepository extends JpaRepository<FoodNutrition, Long> {

    @Query("""
            SELECT f
            FROM FoodNutrition f
            WHERE (f.userId IS NULL OR f.userId = :userId)
              AND LOWER(f.name) LIKE LOWER(CONCAT('%', :keyword, '%'))
            ORDER BY CASE WHEN f.userId = :userId THEN 0 ELSE 1 END,
                     f.category ASC,
                     f.name ASC
            """)
    Page<FoodNutrition> searchAccessibleFoods(
            @Param("userId") Long userId,
            @Param("keyword") String keyword,
            Pageable pageable
    );
}
