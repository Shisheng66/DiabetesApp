package com.diabetes.health.dto;

import com.diabetes.health.entity.PaymentOrder;
import com.diabetes.health.entity.UserSubscription;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

import java.time.Instant;
import java.util.List;

public class CommercialDto {

    public static final String FEATURE_REPORT_EXPORT = "REPORT_EXPORT";
    public static final String FEATURE_AI_MEAL_PLAN = "AI_MEAL_PLAN";
    public static final String FEATURE_FOOD_PHOTO_RECOGNITION = "FOOD_PHOTO_RECOGNITION";
    public static final String FEATURE_GLUCOSE_SMART_ADVICE = "GLUCOSE_SMART_ADVICE";
    public static final String FEATURE_FAMILY_SHARE = "FAMILY_SHARE";

    @Data
    public static class PlanResponse {
        private String code;
        private String name;
        private String description;
        private Integer amountCents;
        private String currency;
        private Integer durationDays;
        private List<String> featureCodes;
        private List<String> featureLabels;
        private Boolean recommended;
    }

    @Data
    public static class SubscriptionResponse {
        private Boolean active;
        private String planCode;
        private String planName;
        private Instant startedAt;
        private Instant expiresAt;
        private List<String> featureCodes;
        private List<String> featureLabels;
    }

    @Data
    public static class FeatureAccessResponse {
        private String featureCode;
        private String featureName;
        private Boolean allowed;
        private String reason;
        private SubscriptionResponse subscription;
    }

    @Data
    public static class CreateOrderRequest {
        @NotBlank(message = "请选择会员套餐")
        @Pattern(regexp = "PREMIUM_MONTH|PREMIUM_YEAR", message = "会员套餐暂不可用")
        private String planCode;
    }

    @Data
    public static class OrderResponse {
        private String orderNo;
        private String planCode;
        private String subject;
        private Integer amountCents;
        private String displayAmount;
        private String status;
        private String statusLabel;
        private Instant createdAt;
        private Instant paidAt;
        private String payHint;

        public static OrderResponse from(PaymentOrder order) {
            OrderResponse r = new OrderResponse();
            r.setOrderNo(order.getOrderNo());
            r.setPlanCode(order.getPlanCode());
            r.setSubject(order.getSubject());
            r.setAmountCents(order.getAmountCents());
            r.setDisplayAmount(String.format("¥%.2f", order.getAmountCents() / 100.0));
            r.setStatus(order.getStatus().name());
            r.setStatusLabel(switch (order.getStatus()) {
                case PENDING -> "待支付";
                case PAID -> "已支付";
                case CLOSED -> "已关闭";
            });
            r.setCreatedAt(order.getCreatedAt());
            r.setPaidAt(order.getPaidAt());
            r.setPayHint("演示环境已创建订单，接入微信/支付宝后可跳转真实支付。开发调试可使用模拟支付按钮。");
            return r;
        }
    }

    public static SubscriptionResponse freeSubscription() {
        SubscriptionResponse r = new SubscriptionResponse();
        r.setActive(false);
        r.setPlanCode("FREE");
        r.setPlanName("基础版");
        r.setFeatureCodes(List.of());
        r.setFeatureLabels(List.of());
        return r;
    }

    public static SubscriptionResponse fromSubscription(
            UserSubscription subscription,
            String planName,
            List<String> featureCodes,
            List<String> featureLabels
    ) {
        SubscriptionResponse r = new SubscriptionResponse();
        r.setActive(true);
        r.setPlanCode(subscription.getPlanCode());
        r.setPlanName(planName);
        r.setStartedAt(subscription.getStartedAt());
        r.setExpiresAt(subscription.getExpiresAt());
        r.setFeatureCodes(featureCodes);
        r.setFeatureLabels(featureLabels);
        return r;
    }
}
