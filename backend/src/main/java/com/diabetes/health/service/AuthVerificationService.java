package com.diabetes.health.service;

import com.diabetes.health.config.AuthVerificationProperties;
import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.repository.UserAccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
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

@Service
@RequiredArgsConstructor
public class AuthVerificationService {

    private static final char[] CAPTCHA_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();

    private final AuthVerificationProperties properties;
    private final UserAccountRepository userAccountRepository;
    private final SmsSender smsSender;

    private final Map<String, CaptchaChallenge> captchaChallenges = new ConcurrentHashMap<>();
    private final Map<String, SmsChallenge> smsChallenges = new ConcurrentHashMap<>();

    public AuthDto.CaptchaResponse createCaptcha() {
        purgeExpired();

        String challengeId = UUID.randomUUID().toString();
        String displayCode = randomCode(4);
        String salt = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = Instant.now().plusSeconds(properties.getCaptchaExpireSeconds());

        captchaChallenges.put(
                challengeId,
                new CaptchaChallenge(hash(displayCode, salt), salt, expiresAt)
        );

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
        SmsChallenge current = smsChallenges.get(key);
        Instant now = Instant.now();
        if (current != null && current.cooldownUntil().isAfter(now)) {
            long remain = Math.max(1, current.cooldownUntil().getEpochSecond() - now.getEpochSecond());
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "请" + remain + "秒后再获取验证码");
        }

        String code = randomDigits(6);
        String salt = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = now.plusSeconds(properties.getSmsExpireSeconds());
        Instant cooldownUntil = now.plusSeconds(properties.getSmsCooldownSeconds());
        smsChallenges.put(
                key,
                new SmsChallenge(hash(code, salt), salt, expiresAt, cooldownUntil, false)
        );

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

        CaptchaChallenge challenge = captchaChallenges.get(challengeId);
        if (challenge == null || challenge.expiresAt().isBefore(Instant.now())) {
            captchaChallenges.remove(challengeId);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "图形验证码已过期，请刷新后重试");
        }

        String actualHash = hash(normalizeCode(captchaCode), challenge.salt());
        if (!challenge.codeHash().equals(actualHash)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "图形验证码错误");
        }

        if (consumeOnSuccess) {
            captchaChallenges.remove(challengeId);
        }
    }

    public void verifySmsCode(String phone, AuthDto.SmsScene scene, String smsCode) {
        purgeExpired();
        if (isBlank(smsCode)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请输入短信验证码");
        }

        String key = smsKey(phone, scene);
        SmsChallenge challenge = smsChallenges.get(key);
        if (challenge == null || challenge.expiresAt().isBefore(Instant.now())) {
            smsChallenges.remove(key);
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "短信验证码已过期，请重新获取");
        }
        if (challenge.used()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "短信验证码已使用，请重新获取");
        }

        String actualHash = hash(smsCode.trim(), challenge.salt());
        if (!challenge.codeHash().equals(actualHash)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "短信验证码错误");
        }

        smsChallenges.put(
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
        captchaChallenges.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
        smsChallenges.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
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

    private record CaptchaChallenge(String codeHash, String salt, Instant expiresAt) {
    }

    private record SmsChallenge(
            String codeHash,
            String salt,
            Instant expiresAt,
            Instant cooldownUntil,
            boolean used
    ) {
    }
}
