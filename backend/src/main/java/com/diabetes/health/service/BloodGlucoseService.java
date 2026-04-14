package com.diabetes.health.service;

import com.diabetes.health.dto.BloodGlucoseDto;
import com.diabetes.health.entity.BloodGlucoseRecord;
import com.diabetes.health.entity.GlucoseAbnormalEvent;
import com.diabetes.health.entity.UserHealthProfile;
import com.diabetes.health.repository.BloodGlucoseRecordRepository;
import com.diabetes.health.repository.GlucoseAbnormalEventRepository;
import com.diabetes.health.repository.UserHealthProfileRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class BloodGlucoseService {

    private final BloodGlucoseRecordRepository recordRepository;
    private final GlucoseAbnormalEventRepository abnormalEventRepository;
    private final UserHealthProfileRepository healthProfileRepository;

    @Transactional
    public BloodGlucoseDto.RecordResponse create(CurrentUser user, BloodGlucoseDto.CreateRecordRequest req) {
        BloodGlucoseRecord.MeasureType measureType;
        try {
            measureType = BloodGlucoseRecord.MeasureType.valueOf(req.getMeasureType().toUpperCase().replace("-", "_"));
        } catch (Exception e) {
            measureType = BloodGlucoseRecord.MeasureType.RANDOM;
        }
        BloodGlucoseRecord.RecordSource source = "BLE".equalsIgnoreCase(req.getSource())
                ? BloodGlucoseRecord.RecordSource.BLE : BloodGlucoseRecord.RecordSource.MANUAL;

        UserHealthProfile profile = healthProfileRepository.findByUserId(user.getId()).orElse(null);
        BigDecimal targetMin = defaultTargetMin(measureType);
        BigDecimal targetMax = defaultTargetMax(measureType);

        if (profile != null) {
            if (measureType == BloodGlucoseRecord.MeasureType.POST_MEAL) {
                if (profile.getTargetPbgMin() != null) {
                    targetMin = profile.getTargetPbgMin();
                }
                if (profile.getTargetPbgMax() != null) {
                    targetMax = profile.getTargetPbgMax();
                }
            } else {
                if (profile.getTargetFbgMin() != null) {
                    targetMin = profile.getTargetFbgMin();
                }
                if (profile.getTargetFbgMax() != null) {
                    targetMax = profile.getTargetFbgMax();
                }
            }
        }

        BloodGlucoseRecord.AbnormalFlag abnormalFlag = BloodGlucoseRecord.AbnormalFlag.NORMAL;
        if (req.getValueMmolL().compareTo(targetMax) > 0) {
            abnormalFlag = BloodGlucoseRecord.AbnormalFlag.HIGH;
        } else if (req.getValueMmolL().compareTo(targetMin) < 0) {
            abnormalFlag = BloodGlucoseRecord.AbnormalFlag.LOW;
        }

        BloodGlucoseRecord record = BloodGlucoseRecord.builder()
                .userId(user.getId())
                .measureTime(req.getMeasureTime())
                .measureType(measureType)
                .valueMmolL(req.getValueMmolL())
                .source(source)
                .deviceId(req.getDeviceId())
                .remark(req.getRemark())
                .abnormalFlag(abnormalFlag)
                .build();
        record = recordRepository.save(record);

        if (abnormalFlag != BloodGlucoseRecord.AbnormalFlag.NORMAL) {
            GlucoseAbnormalEvent event = GlucoseAbnormalEvent.builder()
                    .userId(user.getId())
                    .recordId(record.getId())
                    .type(abnormalFlag == BloodGlucoseRecord.AbnormalFlag.HIGH
                            ? GlucoseAbnormalEvent.EventType.HIGH : GlucoseAbnormalEvent.EventType.LOW)
                    .handled(false)
                    .build();
            abnormalEventRepository.save(event);
        }

        return BloodGlucoseDto.RecordResponse.from(record);
    }

    public BloodGlucoseDto.PageResult<BloodGlucoseDto.RecordResponse> list(CurrentUser user,
                                                                           LocalDate startDate, LocalDate endDate,
                                                                           String measureType, int page, int size) {
        PageRequest pageRequest = PageRequest.of(page, size);
        if (startDate != null && endDate != null) {
            Instant start = startDate.atStartOfDay(ZoneId.systemDefault()).toInstant();
            Instant end = endDate.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
            List<BloodGlucoseRecord> list = recordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(user.getId(), start, end);
            BloodGlucoseRecord.MeasureType typeFilterVal = null;
            if (measureType != null && !measureType.isBlank()) {
                try {
                    typeFilterVal = BloodGlucoseRecord.MeasureType.valueOf(measureType.toUpperCase().replace("-", "_"));
                } catch (Exception ignored) {}
            }
            final BloodGlucoseRecord.MeasureType typeFilter = typeFilterVal;
            if (typeFilter != null) {
                list = list.stream().filter(r -> r.getMeasureType() == typeFilter).toList();
            }
            long total = list.size();
            int from = page * size;
            int to = Math.min(from + size, list.size());
            list = from < list.size() ? list.subList(from, to) : List.of();
            return toPageResult(list, page, size, total);
        }
        Page<BloodGlucoseRecord> pageResult = recordRepository.findByUserIdOrderByMeasureTimeDesc(user.getId(), pageRequest);
        List<BloodGlucoseDto.RecordResponse> resp = pageResult.getContent().stream()
                .map(BloodGlucoseDto.RecordResponse::from)
                .toList();
        BloodGlucoseDto.PageResult<BloodGlucoseDto.RecordResponse> result = new BloodGlucoseDto.PageResult<>();
        result.setContent(resp);
        result.setPage(pageResult.getNumber());
        result.setSize(pageResult.getSize());
        result.setTotalElements(pageResult.getTotalElements());
        result.setTotalPages(pageResult.getTotalPages());
        return result;
    }

    private BloodGlucoseDto.PageResult<BloodGlucoseDto.RecordResponse> toPageResult(List<BloodGlucoseRecord> list,
                                                                                     int page, int size, long total) {
        BloodGlucoseDto.PageResult<BloodGlucoseDto.RecordResponse> result = new BloodGlucoseDto.PageResult<>();
        result.setContent(list.stream().map(BloodGlucoseDto.RecordResponse::from).toList());
        result.setPage(page);
        result.setSize(size);
        result.setTotalElements(total);
        result.setTotalPages((int) ((total + size - 1) / size));
        return result;
    }

    public BloodGlucoseDto.RecordResponse getById(CurrentUser user, Long id) {
        BloodGlucoseRecord record = recordRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "记录不存在"));
        if (!record.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权限");
        }
        return BloodGlucoseDto.RecordResponse.from(record);
    }

    public void delete(CurrentUser user, Long id) {
        BloodGlucoseRecord record = recordRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "记录不存在"));
        if (!record.getUserId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权限");
        }
        recordRepository.delete(record);
    }

    public BloodGlucoseDto.TrendResponse trendDaily(CurrentUser user, LocalDate date) {
        Instant start = date.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = date.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
        List<BloodGlucoseRecord> list = recordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(user.getId(), start, end);
        List<BloodGlucoseDto.TrendPoint> points = new ArrayList<>();
        for (BloodGlucoseRecord r : list) {
            BloodGlucoseDto.TrendPoint p = new BloodGlucoseDto.TrendPoint();
            p.setTime(r.getMeasureTime().atZone(ZoneId.systemDefault()).toLocalTime().toString());
            p.setValue(r.getValueMmolL());
            points.add(p);
        }
        BloodGlucoseDto.TrendResponse res = new BloodGlucoseDto.TrendResponse();
        res.setPeriodType("daily");
        res.setPoints(points);
        return res;
    }

    public BloodGlucoseDto.TrendResponse trendWeekly(CurrentUser user, LocalDate weekStart) {
        Instant start = weekStart.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = weekStart.plusWeeks(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
        List<BloodGlucoseRecord> list = recordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(user.getId(), start, end);
        List<BloodGlucoseDto.TrendPoint> points = new ArrayList<>();
        for (BloodGlucoseRecord r : list) {
            BloodGlucoseDto.TrendPoint p = new BloodGlucoseDto.TrendPoint();
            p.setTime(r.getMeasureTime().atZone(ZoneId.systemDefault()).toLocalDate().toString());
            p.setValue(r.getValueMmolL());
            points.add(p);
        }
        BloodGlucoseDto.TrendResponse res = new BloodGlucoseDto.TrendResponse();
        res.setPeriodType("weekly");
        res.setPoints(points);
        return res;
    }

    public BloodGlucoseDto.TrendResponse trendMonthly(CurrentUser user, int year, int month) {
        LocalDate startDate = LocalDate.of(year, month, 1);
        LocalDate endDate = startDate.plusMonths(1);
        Instant start = startDate.atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = endDate.atStartOfDay(ZoneId.systemDefault()).toInstant();
        List<BloodGlucoseRecord> list = recordRepository.findByUserIdAndMeasureTimeBetweenOrderByMeasureTimeDesc(user.getId(), start, end);
        List<BloodGlucoseDto.TrendPoint> points = new ArrayList<>();
        for (BloodGlucoseRecord r : list) {
            BloodGlucoseDto.TrendPoint p = new BloodGlucoseDto.TrendPoint();
            p.setTime(r.getMeasureTime().atZone(ZoneId.systemDefault()).toLocalDate().toString());
            p.setValue(r.getValueMmolL());
            points.add(p);
        }
        BloodGlucoseDto.TrendResponse res = new BloodGlucoseDto.TrendResponse();
        res.setPeriodType("monthly");
        res.setPoints(points);
        return res;
    }

    public BloodGlucoseDto.PageResult<BloodGlucoseDto.AbnormalEventResponse> listAbnormalEvents(
            CurrentUser user,
            int page,
            int size
    ) {
        PageRequest pageRequest = PageRequest.of(page, size);
        Page<GlucoseAbnormalEvent> pageResult =
                abnormalEventRepository.findByUserIdOrderByCreatedAtDesc(
                        user.getId(),
                        pageRequest
                );
        BloodGlucoseDto.PageResult<BloodGlucoseDto.AbnormalEventResponse> result =
                new BloodGlucoseDto.PageResult<>();
        result.setContent(
                pageResult.getContent().stream()
                        .map(BloodGlucoseDto.AbnormalEventResponse::from)
                        .toList()
        );
        result.setPage(pageResult.getNumber());
        result.setSize(pageResult.getSize());
        result.setTotalElements(pageResult.getTotalElements());
        result.setTotalPages(pageResult.getTotalPages());
        return result;
    }

    private BigDecimal defaultTargetMin(BloodGlucoseRecord.MeasureType measureType) {
        if (measureType == BloodGlucoseRecord.MeasureType.POST_MEAL) {
            return new BigDecimal("4.4");
        }
        return new BigDecimal("3.9");
    }

    private BigDecimal defaultTargetMax(BloodGlucoseRecord.MeasureType measureType) {
        if (measureType == BloodGlucoseRecord.MeasureType.POST_MEAL) {
            return new BigDecimal("7.8");
        }
        return new BigDecimal("6.1");
    }
}
