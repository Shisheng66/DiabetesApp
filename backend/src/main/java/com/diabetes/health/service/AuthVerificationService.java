package com.diabetes.health.service;

import com.diabetes.health.config.AuthVerificationProperties;
import com.diabetes.health.dto.AuthDto;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.diabetes.health.repository.UserAccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import javax.imageio.ImageIO;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
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
    private static final int MAX_CAPTCHA_ATTEMPTS = 5;
    private static final int MAX_SMS_ATTEMPTS = 5;

    private final AuthVerificationProperties properties;
    private final UserAccountRepository userAccountRepository;
    private final SmsSender smsSender;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    private final Map<String, CaptchaChallenge> fallbackCaptchaChallenges = new ConcurrentHashMap<>();
    private final Map<String, SmsChallenge> fallbackSmsChallenges = new ConcurrentHashMap<>();
    private final AtomicBoolean fallbackLogged = new AtomicBoolean(false);

    @Value("${spring.profiles.active:}")
    private String activeProfiles;

    public AuthDto.CaptchaResponse createCaptcha() {
        purgeExpired();

        String challengeId = UUID.randomUUID().toString();
        String code = randomCode(4);
        String salt = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = Instant.now().plusSeconds(properties.getCaptchaExpireSeconds());

        saveCaptchaChallenge(challengeId, new CaptchaChallenge(hash(code, salt), salt, expiresAt));

        AuthDto.CaptchaResponse response = new AuthDto.CaptchaResponse();
        response.setChallengeId(challengeId);
        response.setImageMimeType("image/png");
        response.setImageDataUri(buildCaptchaImageDataUri(code));
        if (properties.isExposeDebugSmsCode()) {
            response.setDisplayCode(code);
        }
        response.setExpiresInSeconds(properties.getCaptchaExpireSeconds());
        return response;
    }

    public AuthDto.SendSmsCodeResponse sendSmsCode(AuthDto.SendSmsCodeRequest request) {
        purgeExpired();

        String phone = request.getPhone().trim();
        AuthDto.SmsScene scene = request.getScene();
        verifyCaptcha(request.getCaptchaChallengeId(), request.getCaptchaCode(), true);

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

        if (challenge.attemptCount() >= MAX_CAPTCHA_ATTEMPTS) {
            deleteCaptchaChallenge(challengeId);
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "图形验证码尝试次数过多，请刷新后重试");
        }

        String actualHash = hash(normalizeCode(captchaCode), challenge.salt());
        if (!MessageDigest.isEqual(
                challenge.codeHash().getBytes(StandardCharsets.UTF_8),
                actualHash.getBytes(StandardCharsets.UTF_8)
        )) {
            challenge.setAttemptCount(challenge.attemptCount() + 1);
            if (challenge.attemptCount() >= MAX_CAPTCHA_ATTEMPTS) {
                deleteCaptchaChallenge(challengeId);
                throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "图形验证码尝试次数过多，请刷新后重试");
            }
            saveCaptchaChallenge(challengeId, challenge);
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
        if (challenge.attemptCount() >= MAX_SMS_ATTEMPTS) {
            deleteSmsChallenge(key);
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "短信验证码尝试次数过多，请重新获取");
        }

        String actualHash = hash(smsCode.trim(), challenge.salt());
        if (!MessageDigest.isEqual(
                challenge.codeHash().getBytes(StandardCharsets.UTF_8),
                actualHash.getBytes(StandardCharsets.UTF_8)
        )) {
            challenge.setAttemptCount(challenge.attemptCount() + 1);
            if (challenge.attemptCount() >= MAX_SMS_ATTEMPTS) {
                deleteSmsChallenge(key);
                throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "短信验证码尝试次数过多，请重新获取");
            }
            saveSmsChallenge(key, challenge);
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
        } catch (DataAccessException | JsonProcessingException ex) {
            failIfProdRedisUnavailable(ex);
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
        } catch (DataAccessException | JsonProcessingException ex) {
            failIfProdRedisUnavailable(ex);
            logFallbackOnce(ex);
            return null;
        }
    }

    private void deleteRedisKey(String key) {
        try {
            redisTemplate.delete(key);
        } catch (DataAccessException ex) {
            failIfProdRedisUnavailable(ex);
            logFallbackOnce(ex);
        }
    }

    private void logFallbackOnce(Exception ex) {
        if (fallbackLogged.compareAndSet(false, true)) {
            log.warn("Redis 不可用，验证码状态暂时退回到内存存储。生产环境请确保 Redis 已启动。原因: {}", ex.getMessage());
        }
    }

    private void failIfProdRedisUnavailable(Exception ex) {
        if (isProd()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "认证状态服务暂时不可用，请稍后重试", ex);
        }
    }

    private boolean isProd() {
        return activeProfiles != null && java.util.Arrays.stream(activeProfiles.split(","))
                .map(String::trim)
                .anyMatch("prod"::equalsIgnoreCase);
    }

    private String buildCaptchaImageDataUri(String code) {
        try {
            int width = 150;
            int height = 50;
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = image.createGraphics();
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setColor(new Color(236, 248, 244));
            g.fillRoundRect(0, 0, width, height, 16, 16);

            for (int i = 0; i < 6; i++) {
                g.setColor(new Color(120 + RANDOM.nextInt(90), 160 + RANDOM.nextInt(70), 150 + RANDOM.nextInt(70), 130));
                g.setStroke(new BasicStroke(1.4f));
                g.drawLine(
                        RANDOM.nextInt(width),
                        RANDOM.nextInt(height),
                        RANDOM.nextInt(width),
                        RANDOM.nextInt(height)
                );
            }

            g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 28));
            for (int i = 0; i < code.length(); i++) {
                AffineTransform old = g.getTransform();
                int x = 22 + i * 30;
                int y = 34 + RANDOM.nextInt(5);
                g.rotate(Math.toRadians(RANDOM.nextInt(21) - 10), x + 9, y - 10);
                g.setColor(new Color(12 + RANDOM.nextInt(30), 70 + RANDOM.nextInt(40), 62 + RANDOM.nextInt(30)));
                g.drawString(String.valueOf(code.charAt(i)), x, y);
                g.setTransform(old);
            }

            g.dispose();
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            ImageIO.write(image, "png", output);
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(output.toByteArray());
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "图形验证码生成失败", ex);
        }
    }

    public static class CaptchaChallenge {

        private String codeHash;
        private String salt;
        private Instant expiresAt;
        private int attemptCount;

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

        public int attemptCount() {
            return attemptCount;
        }

        public int getAttemptCount() {
            return attemptCount;
        }

        public void setAttemptCount(int attemptCount) {
            this.attemptCount = attemptCount;
        }
    }

    public static class SmsChallenge {

        private String codeHash;
        private String salt;
        private Instant expiresAt;
        private Instant cooldownUntil;
        private boolean used;
        private int attemptCount;

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

        public int attemptCount() {
            return attemptCount;
        }

        public int getAttemptCount() {
            return attemptCount;
        }

        public void setAttemptCount(int attemptCount) {
            this.attemptCount = attemptCount;
        }
    }
}
