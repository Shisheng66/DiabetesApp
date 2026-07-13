package com.diabetes.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

public class PaymentDto {

    @Data
    public static class CallbackRequest {
        @NotBlank(message = "订单号不能为空")
        private String orderNo;

        @NotNull(message = "支付金额不能为空")
        @Positive(message = "支付金额不正确")
        private Integer amountCents;

        @NotBlank(message = "支付流水号不能为空")
        private String transactionId;
    }
}
