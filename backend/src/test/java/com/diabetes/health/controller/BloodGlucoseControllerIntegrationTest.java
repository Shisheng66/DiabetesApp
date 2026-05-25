package com.diabetes.health.controller;

import com.diabetes.health.dto.BloodGlucoseDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class BloodGlucoseControllerIntegrationTest extends BaseIntegrationTest {

    private static String token;

    @BeforeEach
    void setUp() {
        if (token == null) {
            token = registerUser("13920000021", "Test1234");
        }
    }

    @Test
    void createRecord_happyPath() {
        var req = new BloodGlucoseDto.CreateRecordRequest();
        req.setMeasureTime(Instant.now());
        req.setMeasureType("FASTING");
        req.setValueMmolL(new BigDecimal("5.6"));

        var resp = authPost("/api/blood-glucose/records", token, req, BloodGlucoseDto.RecordResponse.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody().getId()).isNotNull();
        assertThat(resp.getBody().getValueMmolL()).isEqualByComparingTo("5.6");
    }

    @Test
    void createRecord_invalidValue_returns400() {
        var req = new BloodGlucoseDto.CreateRecordRequest();
        req.setMeasureTime(Instant.now());
        req.setMeasureType("FASTING");
        req.setValueMmolL(new BigDecimal("0.1")); // 低于最小值 1.0

        var resp = authPost("/api/blood-glucose/records", token, req, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void listRecords_returnsPaginatedResult() {
        // 先创建两条记录
        for (int i = 0; i < 2; i++) {
            var req = new BloodGlucoseDto.CreateRecordRequest();
            req.setMeasureTime(Instant.now().minusSeconds(i * 3600L));
            req.setMeasureType("FASTING");
            req.setValueMmolL(new BigDecimal("5." + i));
            authPost("/api/blood-glucose/records", token, req, BloodGlucoseDto.RecordResponse.class);
        }

        var resp = authGet("/api/blood-glucose/records?page=0&size=10", token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).contains("\"totalElements\":2");
    }

    @Test
    void deleteRecord_happyPath() {
        // 创建
        var req = new BloodGlucoseDto.CreateRecordRequest();
        req.setMeasureTime(Instant.now());
        req.setMeasureType("FASTING");
        req.setValueMmolL(new BigDecimal("6.0"));
        var created = authPost("/api/blood-glucose/records", token, req, BloodGlucoseDto.RecordResponse.class);
        Long id = created.getBody().getId();

        // 删除
        var delResp = authDelete("/api/blood-glucose/records/" + id, token, Void.class);
        assertThat(delResp.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void deleteRecord_notOwned_returns404() {
        // 用户 A 创建记录
        var req = new BloodGlucoseDto.CreateRecordRequest();
        req.setMeasureTime(Instant.now());
        req.setMeasureType("FASTING");
        req.setValueMmolL(new BigDecimal("6.0"));
        var created = authPost("/api/blood-glucose/records", token, req, BloodGlucoseDto.RecordResponse.class);
        Long id = created.getBody().getId();

        // 用户 B 尝试删除
        String tokenB = registerUser("13920000022", "Test1234");
        var delResp = authDelete("/api/blood-glucose/records/" + id, tokenB, String.class);
        assertThat(delResp.getStatusCode().is4xxClientError()).isTrue();
    }

    @Test
    void trendDaily_returnsTrendData() {
        // 创建一条记录
        var req = new BloodGlucoseDto.CreateRecordRequest();
        req.setMeasureTime(Instant.now());
        req.setMeasureType("FASTING");
        req.setValueMmolL(new BigDecimal("5.5"));
        authPost("/api/blood-glucose/records", token, req, BloodGlucoseDto.RecordResponse.class);

        String today = LocalDate.now().toString();
        var resp = authGet("/api/blood-glucose/trend/daily?date=" + today, token, String.class);
        assertThat(resp.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(resp.getBody()).contains("日趋势");
    }
}
