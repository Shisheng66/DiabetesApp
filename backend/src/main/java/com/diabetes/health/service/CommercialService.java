package com.diabetes.health.service;

import com.diabetes.health.dto.CommercialDto;
import com.diabetes.health.dto.PaymentDto;
import com.diabetes.health.entity.PaymentOrder;
import com.diabetes.health.entity.UserSubscription;
import com.diabetes.health.repository.PaymentOrderRepository;
import com.diabetes.health.repository.UserSubscriptionRepository;
import com.diabetes.health.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
public class CommercialService {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final DateTimeFormatter ORDER_TIME = DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(ZONE);

    private static final Map<String, FeatureDef> FEATURES = Map.of(
            CommercialDto.FEATURE_REPORT_EXPORT, new FeatureDef(CommercialDto.FEATURE_REPORT_EXPORT, "PDF/图片报告导出"),
            CommercialDto.FEATURE_AI_MEAL_PLAN, new FeatureDef(CommercialDto.FEATURE_AI_MEAL_PLAN, "AI 每日控糖食谱"),
            CommercialDto.FEATURE_FOOD_PHOTO_RECOGNITION, new FeatureDef(CommercialDto.FEATURE_FOOD_PHOTO_RECOGNITION, "饮食拍照热量识别"),
            CommercialDto.FEATURE_GLUCOSE_SMART_ADVICE, new FeatureDef(CommercialDto.FEATURE_GLUCOSE_SMART_ADVICE, "异常血糖智能建议"),
            CommercialDto.FEATURE_FAMILY_SHARE, new FeatureDef(CommercialDto.FEATURE_FAMILY_SHARE, "家属共享与关注提醒")
    );

    private static final Map<String, PlanDef> PLANS = Map.of(
            "PREMIUM_MONTH", new PlanDef(
                    "PREMIUM_MONTH",
                    "高级会员月卡",
                    "解锁报告导出、AI 食谱、拍照识别、异常建议和家属共享。",
                    1990,
                    31,
                    false,
                    List.of(
                            CommercialDto.FEATURE_REPORT_EXPORT,
                            CommercialDto.FEATURE_AI_MEAL_PLAN,
                            CommercialDto.FEATURE_FOOD_PHOTO_RECOGNITION,
                            CommercialDto.FEATURE_GLUCOSE_SMART_ADVICE,
                            CommercialDto.FEATURE_FAMILY_SHARE
                    )
            ),
            "PREMIUM_YEAR", new PlanDef(
                    "PREMIUM_YEAR",
                    "高级会员年卡",
                    "适合长期控糖管理，全年健康报告和营养管家能力。",
                    15900,
                    366,
                    true,
                    List.of(
                            CommercialDto.FEATURE_REPORT_EXPORT,
                            CommercialDto.FEATURE_AI_MEAL_PLAN,
                            CommercialDto.FEATURE_FOOD_PHOTO_RECOGNITION,
                            CommercialDto.FEATURE_GLUCOSE_SMART_ADVICE,
                            CommercialDto.FEATURE_FAMILY_SHARE
                    )
            )
    );

    private final PaymentOrderRepository orderRepository;
    private final UserSubscriptionRepository subscriptionRepository;

    public List<CommercialDto.PlanResponse> listPlans() {
        return PLANS.values().stream()
                .sorted(Comparator.comparing(PlanDef::amountCents))
                .map(this::toPlanResponse)
                .toList();
    }

    public CommercialDto.SubscriptionResponse mySubscription(CurrentUser user) {
        return currentSubscription(user.getId());
    }

    public List<CommercialDto.FeatureAccessResponse> myFeatures(CurrentUser user) {
        CommercialDto.SubscriptionResponse subscription = currentSubscription(user.getId());
        return FEATURES.values().stream()
                .map(feature -> featureAccess(feature.code(), subscription))
                .toList();
    }

    public CommercialDto.FeatureAccessResponse checkFeature(CurrentUser user, String featureCode) {
        FeatureDef feature = featureOrThrow(featureCode);
        return featureAccess(feature, currentSubscription(user.getId()));
    }

    public void requireFeature(CurrentUser user, String featureCode) {
        CommercialDto.FeatureAccessResponse access = checkFeature(user, featureCode);
        if (!Boolean.TRUE.equals(access.getAllowed())) {
            throw new ResponseStatusException(HttpStatus.PAYMENT_REQUIRED, access.getReason());
        }
    }

    @Transactional
    public CommercialDto.OrderResponse createOrder(CurrentUser user, CommercialDto.CreateOrderRequest request) {
        PlanDef plan = planOrThrow(request.getPlanCode());
        String orderNo = buildOrderNo(user.getId());
        PaymentOrder order = PaymentOrder.builder()
                .orderNo(orderNo)
                .userId(user.getId())
                .planCode(plan.code())
                .subject(plan.name())
                .amountCents(plan.amountCents())
                .currency("CNY")
                .status(PaymentOrder.OrderStatus.PENDING)
                .build();
        return CommercialDto.OrderResponse.from(orderRepository.save(order));
    }

    public Page<CommercialDto.OrderResponse> myOrders(CurrentUser user, int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), 50);
        return orderRepository.findByUserIdOrderByCreatedAtDesc(user.getId(), PageRequest.of(Math.max(page, 0), safeSize))
                .map(CommercialDto.OrderResponse::from);
    }

    @Transactional
    public CommercialDto.SubscriptionResponse mockPay(CurrentUser user, String orderNo) {
        PaymentOrder order = orderRepository.findByOrderNoAndUserId(orderNo, user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "订单不存在"));
        if (order.getStatus() == PaymentOrder.OrderStatus.CLOSED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "订单已关闭");
        }
        PlanDef plan = planOrThrow(order.getPlanCode());
        Instant now = Instant.now();
        if (order.getStatus() != PaymentOrder.OrderStatus.PAID) {
            order.setStatus(PaymentOrder.OrderStatus.PAID);
            order.setPaidAt(now);
            orderRepository.save(order);
        }

        Instant startAt = now;
        Optional<UserSubscription> current = subscriptionRepository
                .findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                        user.getId(), UserSubscription.SubscriptionStatus.ACTIVE, now
                );
        if (current.isPresent()) {
            startAt = current.get().getExpiresAt().isAfter(now) ? current.get().getExpiresAt() : now;
        }

        UserSubscription subscription = UserSubscription.builder()
                .userId(user.getId())
                .planCode(plan.code())
                .status(UserSubscription.SubscriptionStatus.ACTIVE)
                .startedAt(now)
                .expiresAt(startAt.plus(Duration.ofDays(plan.durationDays())))
                .sourceOrderNo(order.getOrderNo())
                .build();
        return toSubscriptionResponse(subscriptionRepository.save(subscription), plan);
    }

    /** Processes a signature-verified payment callback. It is not exposed to clients. */
    @Transactional
    public CommercialDto.SubscriptionResponse confirmPaidOrder(PaymentDto.CallbackRequest request) {
        PaymentOrder order = orderRepository.findByOrderNoForUpdate(request.getOrderNo())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "订单不存在"));
        if (!Objects.equals(order.getAmountCents(), request.getAmountCents())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "支付金额校验失败");
        }
        PlanDef plan = planOrThrow(order.getPlanCode());
        Optional<UserSubscription> existing = subscriptionRepository.findBySourceOrderNo(order.getOrderNo());
        if (existing.isPresent()) {
            return toSubscriptionResponse(existing.get(), plan);
        }
        if (order.getStatus() == PaymentOrder.OrderStatus.CLOSED) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "订单已关闭");
        }

        Instant now = Instant.now();
        order.setStatus(PaymentOrder.OrderStatus.PAID);
        if (order.getPaidAt() == null) {
            order.setPaidAt(now);
        }
        orderRepository.save(order);

        Instant startAt = subscriptionRepository
                .findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                        order.getUserId(), UserSubscription.SubscriptionStatus.ACTIVE, now
                )
                .map(UserSubscription::getExpiresAt)
                .filter(expiresAt -> expiresAt.isAfter(now))
                .orElse(now);
        UserSubscription subscription = UserSubscription.builder()
                .userId(order.getUserId())
                .planCode(plan.code())
                .status(UserSubscription.SubscriptionStatus.ACTIVE)
                .startedAt(now)
                .expiresAt(startAt.plus(Duration.ofDays(plan.durationDays())))
                .sourceOrderNo(order.getOrderNo())
                .build();
        return toSubscriptionResponse(subscriptionRepository.save(subscription), plan);
    }

    private CommercialDto.SubscriptionResponse currentSubscription(Long userId) {
        Instant now = Instant.now();
        return subscriptionRepository
                .findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                        userId, UserSubscription.SubscriptionStatus.ACTIVE, now
                )
                .map(subscription -> toSubscriptionResponse(subscription, planOrThrow(subscription.getPlanCode())))
                .orElseGet(CommercialDto::freeSubscription);
    }

    private CommercialDto.PlanResponse toPlanResponse(PlanDef plan) {
        CommercialDto.PlanResponse r = new CommercialDto.PlanResponse();
        r.setCode(plan.code());
        r.setName(plan.name());
        r.setDescription(plan.description());
        r.setAmountCents(plan.amountCents());
        r.setCurrency("CNY");
        r.setDurationDays(plan.durationDays());
        r.setFeatureCodes(plan.featureCodes());
        r.setFeatureLabels(plan.featureCodes().stream().map(code -> featureOrThrow(code).name()).toList());
        r.setRecommended(plan.recommended());
        return r;
    }

    private CommercialDto.SubscriptionResponse toSubscriptionResponse(UserSubscription subscription, PlanDef plan) {
        return CommercialDto.fromSubscription(
                subscription,
                plan.name(),
                plan.featureCodes(),
                plan.featureCodes().stream().map(code -> featureOrThrow(code).name()).toList()
        );
    }

    private CommercialDto.FeatureAccessResponse featureAccess(String featureCode, CommercialDto.SubscriptionResponse subscription) {
        return featureAccess(featureOrThrow(featureCode), subscription);
    }

    private CommercialDto.FeatureAccessResponse featureAccess(FeatureDef feature, CommercialDto.SubscriptionResponse subscription) {
        boolean allowed = Boolean.TRUE.equals(subscription.getActive())
                && subscription.getFeatureCodes() != null
                && subscription.getFeatureCodes().contains(feature.code());
        CommercialDto.FeatureAccessResponse r = new CommercialDto.FeatureAccessResponse();
        r.setFeatureCode(feature.code());
        r.setFeatureName(feature.name());
        r.setAllowed(allowed);
        r.setReason(allowed ? "已开通" : "该功能属于高级会员权益，请开通后使用");
        r.setSubscription(subscription);
        return r;
    }

    private FeatureDef featureOrThrow(String featureCode) {
        FeatureDef feature = FEATURES.get(featureCode);
        if (feature == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "功能暂不可用");
        }
        return feature;
    }

    private PlanDef planOrThrow(String planCode) {
        PlanDef plan = PLANS.get(planCode);
        if (plan == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "会员套餐暂不可用");
        }
        return plan;
    }

    private String buildOrderNo(Long userId) {
        int random = ThreadLocalRandom.current().nextInt(1000, 9999);
        return "ORD" + ORDER_TIME.format(Instant.now()) + userId + random;
    }

    private record FeatureDef(String code, String name) {}

    private record PlanDef(
            String code,
            String name,
            String description,
            Integer amountCents,
            Integer durationDays,
            Boolean recommended,
            List<String> featureCodes
    ) {}
}
