package com.diabetes.health.security;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 当前登录用户，从 JWT 解析后放入 SecurityContext。
 */
@Getter
@AllArgsConstructor
public class CurrentUser {
    private final Long id;
    private final String phone;
    private final String role;
}
