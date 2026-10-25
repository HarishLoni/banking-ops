package com.ops.banking_ops_copilot.monitoring.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "batch_job")
public class BatchJob {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_code", nullable = false, unique = true, length = 64)
    private String jobCode;

    @Column(name = "job_name", nullable = false, length = 150)
    private String jobName;

    @Column(name = "module_name", nullable = false, length = 64)
    private String moduleName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "upstream_job_id")
    private BatchJob upstreamJob;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "required_feed_id")
    private DataFeed requiredFeed;

    @Column(name = "sla_minutes", nullable = false)
    private Integer slaMinutes = 30;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public BatchJob() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getJobCode() { return jobCode; }
    public void setJobCode(String jobCode) { this.jobCode = jobCode; }

    public String getJobName() { return jobName; }
    public void setJobName(String jobName) { this.jobName = jobName; }

    public String getModuleName() { return moduleName; }
    public void setModuleName(String moduleName) { this.moduleName = moduleName; }

    public BatchJob getUpstreamJob() { return upstreamJob; }
    public void setUpstreamJob(BatchJob upstreamJob) { this.upstreamJob = upstreamJob; }

    public DataFeed getRequiredFeed() { return requiredFeed; }
    public void setRequiredFeed(DataFeed requiredFeed) { this.requiredFeed = requiredFeed; }

    public Integer getSlaMinutes() { return slaMinutes; }
    public void setSlaMinutes(Integer slaMinutes) { this.slaMinutes = slaMinutes; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

