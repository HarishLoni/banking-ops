package com.ops.banking_ops_copilot.monitoring.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public record ReportExecutionResponse(
    Long id,
    String reportCode,
    String reportName,
    String category,
    LocalDate businessDate,
    String correlationId,
    String status,
    BigDecimal expectedTotal,
    BigDecimal actualTotal,
    BigDecimal variance,
    String failureReason,
    Instant startedAt,
    Instant completedAt
) {}

