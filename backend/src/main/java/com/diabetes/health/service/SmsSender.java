package com.diabetes.health.service;

import com.diabetes.health.dto.AuthDto;

public interface SmsSender {

    void sendVerificationCode(String phone, String code, AuthDto.SmsScene scene);
}
