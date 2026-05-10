package com.diabetes.health.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(ResponseStatusException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", sanitizeMessage(e.getReason(), "请求处理失败，请稍后重试"));
        body.put("status", e.getStatusCode().value());
        return ResponseEntity.status(e.getStatusCode()).body(body);
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<Map<String, Object>> handleAuth(AuthenticationException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", "未登录或登录已过期");
        body.put("status", 401);
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException e) {
        Map<String, Object> body = new HashMap<>();
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(error -> sanitizeMessage(error.getDefaultMessage(), "请检查填写内容"))
                .findFirst()
                .orElse("请检查填写内容");
        body.put("message", message);
        body.put("status", 400);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleNotReadable(HttpMessageNotReadableException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", "请求格式错误");
        body.put("status", 400);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> handleMissingParam(MissingServletRequestParameterException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", "缺少必填信息，请检查后重试");
        body.put("status", 400);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(AccessDeniedException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", "权限不足");
        body.put("status", 403);
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneral(Exception e) {
        log.error("Unhandled exception", e);
        Map<String, Object> body = new HashMap<>();
        body.put("message", "服务暂时不可用，请稍后重试");
        body.put("status", 500);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }

    private String sanitizeMessage(String message, String fallback) {
        if (message == null || message.isBlank()) {
            return fallback;
        }
        String sanitized = message
                .replaceAll("[:：]\\s*[A-Z0-9_./-]+$", "")
                .replaceAll("\\b[A-Z]{2,}_[A-Z0-9_]+\\b", "相关选项")
                .replaceAll("https?://\\S+", "")
                .trim();
        if (sanitized.isBlank()) {
            return fallback;
        }
        return sanitized;
    }
}
