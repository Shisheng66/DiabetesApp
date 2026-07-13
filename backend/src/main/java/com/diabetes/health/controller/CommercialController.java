package com.diabetes.health.controller;

import com.diabetes.health.dto.CommercialDto;
import com.diabetes.health.security.CurrentUser;
import com.diabetes.health.service.CommercialService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/commercial")
@RequiredArgsConstructor
public class CommercialController {

    private final CommercialService commercialService;

    @GetMapping("/plans")
    public List<CommercialDto.PlanResponse> plans() {
        return commercialService.listPlans();
    }

    @GetMapping("/subscription/me")
    public CommercialDto.SubscriptionResponse mySubscription(@AuthenticationPrincipal CurrentUser user) {
        return commercialService.mySubscription(user);
    }

    @GetMapping("/features")
    public List<CommercialDto.FeatureAccessResponse> features(@AuthenticationPrincipal CurrentUser user) {
        return commercialService.myFeatures(user);
    }

    @GetMapping("/features/{featureCode}")
    public CommercialDto.FeatureAccessResponse checkFeature(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable String featureCode) {
        return commercialService.checkFeature(user, featureCode);
    }

    @PostMapping("/orders")
    public CommercialDto.OrderResponse createOrder(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody CommercialDto.CreateOrderRequest request) {
        return commercialService.createOrder(user, request);
    }

    @GetMapping("/orders")
    public Page<CommercialDto.OrderResponse> myOrders(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return commercialService.myOrders(user, page, size);
    }

}
