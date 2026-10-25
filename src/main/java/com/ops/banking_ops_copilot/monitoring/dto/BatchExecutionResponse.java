package com.ops.banking_ops_copilot.monitoring.dto;

import java.time.Instant;
import java.time.LocalDate;

public record BatchExecutionResponse(
    Long id,
    String jobCode,
    String jobName,
    String moduleName,
    LocalDate businessDate,
    String correlationId,
    String status,
    Integer recordsProcessed,
    Integer recordsFailed,
    String exitCode,
    String errorSummary,
    Instant startedAt,
    Instant endedAt
) {}

