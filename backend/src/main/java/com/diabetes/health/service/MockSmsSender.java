package com.diabetes.health.service;

import com.diabetes.health.dto.AuthDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@Profile({"dev", "test"})
public class MockSmsSender implements SmsSender {

    @Override
    public void sendVerificationCode(String phone, String code, AuthDto.SmsScene scene) {
        log.info("[DEV-SMS] scene={} phone={} code={}", scene, phone, code);
    }

    @Override
    public boolean isMock() {
        return true;
    }
}
