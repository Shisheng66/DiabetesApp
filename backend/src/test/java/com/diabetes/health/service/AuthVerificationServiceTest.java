package com.diabetes.health.service;

import com.diabetes.health.config.AuthVerificationProperties;
import com.diabetes.health.dto.AuthDto;
import com.diabetes.health.repository.UserAccountRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthVerificationServiceTest {

    @Mock
    private UserAccountRepository userAccountRepository;

    @Mock
    private SmsSender smsSender;

    private AuthVerificationService authVerificationService;

    @BeforeEach
    void setUp() {
        AuthVerificationProperties properties = new AuthVerificationProperties();
        properties.setCaptchaExpireSeconds(180);
        properties.setSmsExpireSeconds(300);
        properties.setSmsCooldownSeconds(60);
        properties.setExposeDebugSmsCode(true);
        authVerificationService = new AuthVerificationService(properties, userAccountRepository, smsSender);
    }

    @Test
    void captchaCanBeVerifiedOnlyOnce() {
        AuthDto.CaptchaResponse captcha = authVerificationService.createCaptcha();

        authVerificationService.verifyCaptcha(captcha.getChallengeId(), captcha.getDisplayCode(), true);

        assertThatThrownBy(() ->
                authVerificationService.verifyCaptcha(captcha.getChallengeId(), captcha.getDisplayCode(), true)
        )
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("图形验证码已过期");
    }

    @Test
    void registerSmsCodeCanBeSentAndConsumed() {
        when(userAccountRepository.existsByPhone("13800138000")).thenReturn(false);

        AuthDto.CaptchaResponse captcha = authVerificationService.createCaptcha();
        AuthDto.SendSmsCodeRequest request = new AuthDto.SendSmsCodeRequest();
        request.setPhone("13800138000");
        request.setScene(AuthDto.SmsScene.REGISTER);
        request.setCaptchaChallengeId(captcha.getChallengeId());
        request.setCaptchaCode(captcha.getDisplayCode());

        AuthDto.SendSmsCodeResponse response = authVerificationService.sendSmsCode(request);

        assertThat(response.getDebugCode()).hasSize(6);
        authVerificationService.verifySmsCode("13800138000", AuthDto.SmsScene.REGISTER, response.getDebugCode());

        assertThatThrownBy(() ->
                authVerificationService.verifySmsCode("13800138000", AuthDto.SmsScene.REGISTER, response.getDebugCode())
        )
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("短信验证码已使用");
    }
}
