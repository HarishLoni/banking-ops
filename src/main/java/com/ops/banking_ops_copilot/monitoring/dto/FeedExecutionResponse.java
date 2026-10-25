package com.ops.banking_ops_copilot.monitoring.dto;

import java.time.Instant;
import java.time.LocalDate;

public record FeedExecutionResponse(
    Long id,
    String feedCode,
    String feedName,
    String sourceSystem,
    LocalDate businessDate,
    String correlationId,
    String status,
    Integer recordCount,
    String fileName,
    String errorCode,
    String errorMessage,
    Instant arrivedAt,
    Instant completedAt
) {}

