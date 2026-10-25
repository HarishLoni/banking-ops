package com.ops.banking_ops_copilot.monitoring.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "report_definition")
public class ReportDefinition {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "report_code", nullable = false, unique = true, length = 64)
    private String reportCode;

    @Column(name = "report_name", nullable = false, length = 150)
    private String reportName;

    @Column(name = "category", nullable = false, length = 64)
    private String category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "depends_on_job_id", nullable = false)
    private BatchJob dependsOnJob;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public ReportDefinition() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getReportCode() { return reportCode; }
    public void setReportCode(String reportCode) { this.reportCode = reportCode; }

    public String getReportName() { return reportName; }
    public void setReportName(String reportName) { this.reportName = reportName; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public BatchJob getDependsOnJob() { return dependsOnJob; }
    public void setDependsOnJob(BatchJob dependsOnJob) { this.dependsOnJob = dependsOnJob; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

