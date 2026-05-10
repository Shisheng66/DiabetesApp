package com.diabetes.health.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public final class MathUtil {
    private MathUtil() {}

    public static BigDecimal sum(List<BigDecimal> values) {
        BigDecimal result = BigDecimal.ZERO;
        for (BigDecimal value : values) {
            if (value != null) {
                result = result.add(value);
            }
        }
        return result.setScale(2, RoundingMode.HALF_UP);
    }
}
