package com.diabetes.health.util;

import org.springframework.data.domain.PageRequest;

public final class PaginationUtils {

    public static final int DEFAULT_MAX_SIZE = 100;

    private PaginationUtils() {
    }

    public static PageRequest pageRequest(int page, int size) {
        return pageRequest(page, size, DEFAULT_MAX_SIZE);
    }

    public static PageRequest pageRequest(int page, int size, int maxSize) {
        return PageRequest.of(safePage(page), safeSize(size, maxSize));
    }

    public static int safePage(int page) {
        return Math.max(page, 0);
    }

    public static int safeSize(int size, int maxSize) {
        int upperBound = Math.max(1, maxSize);
        return Math.min(Math.max(size, 1), upperBound);
    }
}
