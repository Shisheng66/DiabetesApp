package com.diabetes.health.service;

import com.diabetes.health.dto.CommercialDto;
import com.diabetes.health.entity.PaymentOrder;
import com.diabetes.health.entity.UserSubscription;
import com.diabetes.health.repository.PaymentOrderRepository;
import com.diabetes.health.repository.UserSubscriptionRepository;
import com.diabetes.health.security.CurrentUser;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CommercialServiceTest {

    @Mock private PaymentOrderRepository orderRepository;
    @Mock private UserSubscriptionRepository subscriptionRepository;
    @InjectMocks private CommercialService commercialService;

    private CurrentUser currentUser() {
        return new CurrentUser(1L, "13800138000", "PATIENT");
    }

    @Test
    void listPlans_returnsTwoPlansSortedByPrice() {
        var plans = commercialService.listPlans();
        assertThat(plans).hasSize(2);
        assertThat(plans.get(0).getAmountCents()).isLessThan(plans.get(1).getAmountCents());
        assertThat(plans.get(0).getCode()).isEqualTo("PREMIUM_MONTH");
        assertThat(plans.get(1).getCode()).isEqualTo("PREMIUM_YEAR");
    }

    @Test
    void listPlans_monthPlanHasCorrectDetails() {
        var plans = commercialService.listPlans();
        var month = plans.stream().filter(p -> "PREMIUM_MONTH".equals(p.getCode())).findFirst().orElseThrow();
        assertThat(month.getAmountCents()).isEqualTo(1990);
        assertThat(month.getDurationDays()).isEqualTo(31);
        assertThat(month.getCurrency()).isEqualTo("CNY");
        assertThat(month.getFeatureCodes()).hasSize(5);
    }

    @Test
    void mySubscription_noActive_returnsFree() {
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.empty());

        var result = commercialService.mySubscription(currentUser());
        assertThat(result.getActive()).isFalse();
        assertThat(result.getPlanCode()).isEqualTo("FREE");
    }

    @Test
    void mySubscription_hasActive_returnsPlan() {
        UserSubscription sub = UserSubscription.builder()
                .id(1L).userId(1L).planCode("PREMIUM_MONTH")
                .status(UserSubscription.SubscriptionStatus.ACTIVE)
                .startedAt(Instant.now().minus(1, ChronoUnit.DAYS))
                .expiresAt(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.of(sub));

        var result = commercialService.mySubscription(currentUser());
        assertThat(result.getActive()).isTrue();
        assertThat(result.getPlanCode()).isEqualTo("PREMIUM_MONTH");
    }

    @Test
    void checkFeature_freeUser_notAllowed() {
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.empty());

        var result = commercialService.checkFeature(currentUser(), CommercialDto.FEATURE_REPORT_EXPORT);
        assertThat(result.getAllowed()).isFalse();
        assertThat(result.getReason()).contains("高级会员");
    }

    @Test
    void checkFeature_invalidFeature_throws400() {
        assertThatThrownBy(() -> commercialService.checkFeature(currentUser(), "INVALID_FEATURE"))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void requireFeature_freeUser_throws402() {
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> commercialService.requireFeature(currentUser(), CommercialDto.FEATURE_AI_MEAL_PLAN))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void requireFeature_activeUser_succeeds() {
        UserSubscription sub = UserSubscription.builder()
                .id(1L).userId(1L).planCode("PREMIUM_YEAR")
                .status(UserSubscription.SubscriptionStatus.ACTIVE)
                .startedAt(Instant.now().minus(1, ChronoUnit.DAYS))
                .expiresAt(Instant.now().plus(365, ChronoUnit.DAYS))
                .build();
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.of(sub));

        assertThatCode(() -> commercialService.requireFeature(currentUser(), CommercialDto.FEATURE_FOOD_PHOTO_RECOGNITION))
                .doesNotThrowAnyException();
    }

    @Test
    void createOrder_createsPendingOrder() {
        when(orderRepository.save(any())).thenAnswer(inv -> {
            PaymentOrder o = inv.getArgument(0);
            o.setId(1L);
            return o;
        });

        CommercialDto.CreateOrderRequest req = new CommercialDto.CreateOrderRequest();
        req.setPlanCode("PREMIUM_MONTH");

        var result = commercialService.createOrder(currentUser(), req);
        assertThat(result.getPlanCode()).isEqualTo("PREMIUM_MONTH");
        assertThat(result.getStatus()).isEqualTo("PENDING");
        assertThat(result.getAmountCents()).isEqualTo(1990);
        verify(orderRepository).save(argThat(o -> o.getStatus() == PaymentOrder.OrderStatus.PENDING));
    }

    @Test
    void createOrder_invalidPlan_throws400() {
        CommercialDto.CreateOrderRequest req = new CommercialDto.CreateOrderRequest();
        req.setPlanCode("INVALID_PLAN");

        assertThatThrownBy(() -> commercialService.createOrder(currentUser(), req))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void mockPay_pendingOrder_createsSubscription() {
        PaymentOrder order = PaymentOrder.builder()
                .id(1L).orderNo("ORD202601011200001234").userId(1L)
                .planCode("PREMIUM_MONTH").subject("高级会员月卡")
                .amountCents(1990).currency("CNY")
                .status(PaymentOrder.OrderStatus.PENDING).build();
        when(orderRepository.findByOrderNoAndUserId("ORD202601011200001234", 1L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(subscriptionRepository.save(any())).thenAnswer(inv -> {
            UserSubscription s = inv.getArgument(0);
            s.setId(1L);
            return s;
        });

        var result = commercialService.mockPay(currentUser(), "ORD202601011200001234");
        assertThat(result.getActive()).isTrue();
        assertThat(result.getPlanCode()).isEqualTo("PREMIUM_MONTH");
        verify(orderRepository).save(argThat(o -> o.getStatus() == PaymentOrder.OrderStatus.PAID));
    }

    @Test
    void mockPay_orderNotFound_throws404() {
        when(orderRepository.findByOrderNoAndUserId("nonexistent", 1L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> commercialService.mockPay(currentUser(), "nonexistent"))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void mockPay_closedOrder_throws400() {
        PaymentOrder order = PaymentOrder.builder()
                .id(1L).orderNo("ORD123").userId(1L)
                .planCode("PREMIUM_MONTH").subject("高级会员月卡")
                .amountCents(1990).currency("CNY")
                .status(PaymentOrder.OrderStatus.CLOSED).build();
        when(orderRepository.findByOrderNoAndUserId("ORD123", 1L)).thenReturn(Optional.of(order));

        assertThatThrownBy(() -> commercialService.mockPay(currentUser(), "ORD123"))
                .isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void mockPay_alreadyPaid_returnsExistingSubscription() {
        PaymentOrder order = PaymentOrder.builder()
                .id(1L).orderNo("ORD123").userId(1L)
                .planCode("PREMIUM_MONTH").subject("高级会员月卡")
                .amountCents(1990).currency("CNY")
                .status(PaymentOrder.OrderStatus.PAID)
                .paidAt(Instant.now().minus(1, ChronoUnit.HOURS)).build();
        when(orderRepository.findByOrderNoAndUserId("ORD123", 1L)).thenReturn(Optional.of(order));

        UserSubscription existingSub = UserSubscription.builder()
                .id(1L).userId(1L).planCode("PREMIUM_MONTH")
                .status(UserSubscription.SubscriptionStatus.ACTIVE)
                .startedAt(Instant.now().minus(1, ChronoUnit.HOURS))
                .expiresAt(Instant.now().plus(30, ChronoUnit.DAYS))
                .build();
        when(subscriptionRepository.findFirstByUserIdAndStatusAndExpiresAtAfterOrderByExpiresAtDesc(
                eq(1L), eq(UserSubscription.SubscriptionStatus.ACTIVE), any(Instant.class)))
                .thenReturn(Optional.of(existingSub));
        when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var result = commercialService.mockPay(currentUser(), "ORD123");
        assertThat(result.getActive()).isTrue();
        // Should not re-save the order since it's already PAID
        verify(orderRepository, never()).save(any());
    }
}
