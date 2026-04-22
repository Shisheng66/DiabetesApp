package com.diabetes.health.service;

import com.diabetes.health.config.AuthVerificationProperties;
import com.diabetes.health.dto.AuthDto;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.diabetes.health.repository.UserAccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.time.Duration;

@Service
@Slf4j
@RequiredArgsConstructor
public class AuthVerificationService {

    private static final char[] CAPTCHA_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String CAPTCHA_KEY_PREFIX = "auth:captcha:";
    private static final String SMS_KEY_PREFIX = "auth:sms:";

    private final AuthVerificationProperties properties;
    private final UserAccountRepository userAccountRepository;
    private final SmsSender smsSender;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    private final Map<String, CaptchaChallenge> fallbackCaptchaChallenges = new ConcurrentHashMap<>();
    private final Map<String, SmsChallenge> fallbackSmsChallenges = new ConcurrentHashMap<>();
    private final AtomicBoolean fallbackLogged = new AtomicBoolean(false);

    public AuthDto.CaptchaResponse createCaptcha() {
        purgeExpired();

        String challengeId = UUID.randomUUID().toString();
        String displayCode = randomCode(4);
        String salt = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = Instant.now().plusSeconds(properties.getCaptchaExpireSeconds());

        saveCaptchaChallenge(challengeId, new CaptchaChallenge(hash(displayCode, salt), salt, expiresAt));

        AuthDto.CaptchaResponse response = new AuthDto.CaptchaResponse();
        response.setChallengeId(challengeId);
        response.setDisplayCode(displayCode);
        response.setExpiresInSeconds(properties.getCaptchaExpireSeconds());
        return response;
    }

    public AuthDto.SendSmsCodeResponse sendSmsCode(AuthDto.SendSmsCodeRequest request) {
        purgeExpired();

        String phone = request.getPhone().trim();
        AuthDto.SmsScene scene = request.getScene();

        boolean accountExists = userAccountRepository.existsByPhone(phone);
        if (scene == AuthDto.SmsScene.REGISTER && accountExists) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "该手机号已注册");
        }
        if (scene == AuthDto.SmsScene.LOGIN && !accountExists) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "该手机号尚未注册");
        }

        String key = smsKey(phone, scene);
        SmsChallenge current = getSmsChallenge(key);
        Instant now = Instant.now();
        if (current != null && current.cooldownUntil().isAfter(now)) {
            long remain = Math.max(1, current.cooldownUntil().getEpochSecond() - now.getEpochSecond());
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "请" + remain + "秒后再获取验证码");
        }

        String code = randomDigits(6);
        String salt = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = now.plusSeconds(properties.getSmsExpireSeconds());
        Instant cooldownUntil = now.plusSeconds(properties.getSmsCooldownSeconds());
        saveSmsChallenge(key, new SmsChallenge(hash(code, salt), salt, expiresAt, cooldownUntil, false));

        smsSender.sendVerificationCode(phone, code, scene);

        AuthDto.SendSmsCodeResponse response = new AuthDto.SendSmsCodeResponse();
        response.setCooldownSeconds(properties.getSmsCooldownSeconds());
        response.setExpiresInSeconds(properties.getSmsExpireSeconds());
        response.setMock(true);
        response.setMessage("验证码已发送，请注意查收短信");
        if (properties.isExposeDebugSmsCode()) {
            response.setDebugCode(code);
        }
        return response;
    }

    public void verifyCaptcha(String challengeId, String captchaCode, boolean consumeOnSuccess) {
        purgeExpired();
        if (isBlank(challengeId) || isBlank(captchaCode)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请输入图形验证码");
        }

        CaptchaChallenge challenge = getCaptchaChallenge(challengeId);
        if (challenge == null || challenge.expiresAt().isBefore(Instant.now())) {
            deleteCaptchaChallenge(challengeId);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "图形验证码已过期，请刷新后重试");
        }

        String actualHash = hash(normalizeCode(captchaCode), challenge.salt());
        if (!challenge.codeHash().equals(actualHash)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "图形验证码错误");
        }

        if (consumeOnSuccess) {
            deleteCaptchaChallenge(challengeId);
        }
    }

    public void verifySmsCode(String phone, AuthDto.SmsScene scene, String smsCode) {
        purgeExpired();
        if (isBlank(smsCode)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请输入短信验证码");
        }

        String key = smsKey(phone, scene);
        SmsChallenge challenge = getSmsChallenge(key);
        if (challenge == null || challenge.expiresAt().isBefore(Instant.now())) {
            deleteSmsChallenge(key);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "短信验证码已过期，请重新获取");
        }
        if (challenge.used()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "短信验证码已使用，请重新获取");
        }

        String actualHash = hash(smsCode.trim(), challenge.salt());
        if (!challenge.codeHash().equals(actualHash)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "短信验证码错误");
        }

        saveSmsChallenge(
                key,
                new SmsChallenge(
                        challenge.codeHash(),
                        challenge.salt(),
                        challenge.expiresAt(),
                        challenge.cooldownUntil(),
                        true
                )
        );
    }

    private void purgeExpired() {
        Instant now = Instant.now();
        fallbackCaptchaChallenges.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
        fallbackSmsChallenges.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
    }

    private String smsKey(String phone, AuthDto.SmsScene scene) {
        return phone.trim() + ":" + scene.name();
    }

    private String randomCode(int length) {
        StringBuilder builder = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            builder.append(CAPTCHA_CHARS[RANDOM.nextInt(CAPTCHA_CHARS.length)]);
        }
        return builder.toString();
    }

    private String randomDigits(int length) {
        StringBuilder builder = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            builder.append(RANDOM.nextInt(10));
        }
        return builder.toString();
    }

    private String hash(String value, String salt) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest((normalizeCode(value) + ":" + salt).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashed);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not supported", e);
        }
    }

    private String normalizeCode(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void saveCaptchaChallenge(String challengeId, CaptchaChallenge challenge) {
        if (writeRedisJson(
                CAPTCHA_KEY_PREFIX + challengeId,
                challenge,
                Duration.between(Instant.now(), challenge.expiresAt())
        )) {
            fallbackCaptchaChallenges.remove(challengeId);
            return;
        }
        fallbackCaptchaChallenges.put(challengeId, challenge);
    }

    private CaptchaChallenge getCaptchaChallenge(String challengeId) {
        CaptchaChallenge challenge = readRedisJson(CAPTCHA_KEY_PREFIX + challengeId, CaptchaChallenge.class);
        if (challenge != null) {
            return challenge;
        }
        return fallbackCaptchaChallenges.get(challengeId);
    }

    private void deleteCaptchaChallenge(String challengeId) {
        deleteRedisKey(CAPTCHA_KEY_PREFIX + challengeId);
        fallbackCaptchaChallenges.remove(challengeId);
    }

    private void saveSmsChallenge(String key, SmsChallenge challenge) {
        if (writeRedisJson(
                SMS_KEY_PREFIX + key,
                challenge,
                Duration.between(Instant.now(), challenge.expiresAt())
        )) {
            fallbackSmsChallenges.remove(key);
            return;
        }
        fallbackSmsChallenges.put(key, challenge);
    }

    private SmsChallenge getSmsChallenge(String key) {
        SmsChallenge challenge = readRedisJson(SMS_KEY_PREFIX + key, SmsChallenge.class);
        if (challenge != null) {
            return challenge;
        }
        return fallbackSmsChallenges.get(key);
    }

    private void deleteSmsChallenge(String key) {
        deleteRedisKey(SMS_KEY_PREFIX + key);
        fallbackSmsChallenges.remove(key);
    }

    private boolean writeRedisJson(String key, Object value, Duration ttl) {
        if (ttl.isNegative() || ttl.isZero()) {
            return false;
        }
        try {
            redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(value), ttl);
            return true;
        } catch (RedisConnectionFailureException | JsonProcessingException ex) {
            logFallbackOnce(ex);
            return false;
        }
    }

    private <T> T readRedisJson(String key, Class<T> type) {
        try {
            String raw = redisTemplate.opsForValue().get(key);
            if (raw == null || raw.isBlank()) {
                return null;
            }
            return objectMapper.readValue(raw, type);
        } catch (RedisConnectionFailureException | JsonProcessingException ex) {
            logFallbackOnce(ex);
            return null;
        }
    }

    private void deleteRedisKey(String key) {
        try {
            redisTemplate.delete(key);
        } catch (RedisConnectionFailureException ex) {
            logFallbackOnce(ex);
        }
    }

    private void logFallbackOnce(Exception ex) {
        if (fallbackLogged.compareAndSet(false, true)) {
            log.warn("Redis 不可用，验证码状态暂时退回到内存存储。生产环境请确保 Redis 已启动。原因: {}", ex.getMessage());
        }
    }

    public static class CaptchaChallenge {

        private String codeHash;
        private String salt;
        private Instant expiresAt;

        public CaptchaChallenge() {
        }

        public CaptchaChallenge(String codeHash, String salt, Instant expiresAt) {
            this.codeHash = codeHash;
            this.salt = salt;
            this.expiresAt = expiresAt;
        }

        public String codeHash() {
            return codeHash;
        }

        public String getCodeHash() {
            return codeHash;
        }

        public void setCodeHash(String codeHash) {
            this.codeHash = codeHash;
        }

        public String salt() {
            return salt;
        }

        public String getSalt() {
            return salt;
        }

        public void setSalt(String salt) {
            this.salt = salt;
        }

        public Instant expiresAt() {
            return expiresAt;
        }

        public Instant getExpiresAt() {
            return expiresAt;
        }

        public void setExpiresAt(Instant expiresAt) {
            this.expiresAt = expiresAt;
        }
    }

    public static class SmsChallenge {

        private String codeHash;
        private String salt;
        private Instant expiresAt;
        private Instant cooldownUntil;
        private boolean used;

        public SmsChallenge() {
        }

        public SmsChallenge(String codeHash, String salt, Instant expiresAt, Instant cooldownUntil, boolean used) {
            this.codeHash = codeHash;
            this.salt = salt;
            this.expiresAt = expiresAt;
            this.cooldownUntil = cooldownUntil;
            this.used = used;
        }

        public String codeHash() {
            return codeHash;
        }

        public String getCodeHash() {
            return codeHash;
        }

        public void setCodeHash(String codeHash) {
            this.codeHash = codeHash;
        }

        public String salt() {
            return salt;
        }

        public String getSalt() {
            return salt;
        }

        public void setSalt(String salt) {
            this.salt = salt;
        }

        public Instant expiresAt() {
            return expiresAt;
        }

        public Instant getExpiresAt() {
            return expiresAt;
        }

        public void setExpiresAt(Instant expiresAt) {
            this.expiresAt = expiresAt;
        }

        public Instant cooldownUntil() {
            return cooldownUntil;
        }

        public Instant getCooldownUntil() {
            return cooldownUntil;
        }

        public void setCooldownUntil(Instant cooldownUntil) {
            this.cooldownUntil = cooldownUntil;
        }

        public boolean used() {
            return used;
        }

        public boolean isUsed() {
            return used;
        }

        public void setUsed(boolean used) {
            this.used = used;
        }
    }
}
