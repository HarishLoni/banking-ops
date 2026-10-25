package com.ops.banking_ops_copilot.monitoring.repository;

import com.ops.banking_ops_copilot.monitoring.entity.FeedExecution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface FeedExecutionRepository extends JpaRepository<FeedExecution, Long> {
    List<FeedExecution> findByBusinessDate(LocalDate businessDate);
    Optional<FeedExecution> findByDataFeed_FeedCodeAndBusinessDate(String feedCode, LocalDate businessDate);
    Optional<FeedExecution> findByCorrelationId(String correlationId);
}

