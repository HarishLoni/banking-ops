package com.ops.banking_ops_copilot.monitoring.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalTime;

@Entity
@Table(name = "data_feed")
public class DataFeed {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "feed_code", nullable = false, unique = true, length = 64)
    private String feedCode;

    @Column(name = "feed_name", nullable = false, length = 150)
    private String feedName;

    @Column(name = "source_system", nullable = false, length = 100)
    private String sourceSystem;

    @Column(name = "expected_by_utc", nullable = false)
    private LocalTime expectedByUtc;

    @Column(name = "criticality", nullable = false, length = 20)
    private String criticality;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public DataFeed() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFeedCode() { return feedCode; }
    public void setFeedCode(String feedCode) { this.feedCode = feedCode; }

    public String getFeedName() { return feedName; }
    public void setFeedName(String feedName) { this.feedName = feedName; }

    public String getSourceSystem() { return sourceSystem; }
    public void setSourceSystem(String sourceSystem) { this.sourceSystem = sourceSystem; }

    public LocalTime getExpectedByUtc() { return expectedByUtc; }
    public void setExpectedByUtc(LocalTime expectedByUtc) { this.expectedByUtc = expectedByUtc; }

    public String getCriticality() { return criticality; }
    public void setCriticality(String criticality) { this.criticality = criticality; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

