package com.ops.banking_ops_copilot.monitoring.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "report_execution")
public class ReportExecution {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id", nullable = false)
    private ReportDefinition reportDefinition;

    @Column(name = "business_date", nullable = false)
    private LocalDate businessDate;

    @Column(name = "correlation_id", nullable = false, length = 64)
    private String correlationId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "expected_total", precision = 18, scale = 2)
    private BigDecimal expectedTotal;

    @Column(name = "actual_total", precision = 18, scale = 2)
    private BigDecimal actualTotal;

    @Column(name = "failure_reason", columnDefinition = "TEXT")
    private String failureReason;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    public ReportExecution() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public ReportDefinition getReportDefinition() { return reportDefinition; }
    public void setReportDefinition(ReportDefinition reportDefinition) { this.reportDefinition = reportDefinition; }

    public LocalDate getBusinessDate() { return businessDate; }
    public void setBusinessDate(LocalDate businessDate) { this.businessDate = businessDate; }

    public String getCorrelationId() { return correlationId; }
    public void setCorrelationId(String correlationId) { this.correlationId = correlationId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public BigDecimal getExpectedTotal() { return expectedTotal; }
    public void setExpectedTotal(BigDecimal expectedTotal) { this.expectedTotal = expectedTotal; }

    public BigDecimal getActualTotal() { return actualTotal; }
    public void setActualTotal(BigDecimal actualTotal) { this.actualTotal = actualTotal; }

    public String getFailureReason() { return failureReason; }
    public void setFailureReason(String failureReason) { this.failureReason = failureReason; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getCompletedAt() { return completedAt; }
    public void setCompletedAt(Instant completedAt) { this.completedAt = completedAt; }
}

