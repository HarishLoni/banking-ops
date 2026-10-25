package com.ops.banking_ops_copilot.monitoring.repository;

import com.ops.banking_ops_copilot.monitoring.entity.BatchExecution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface BatchExecutionRepository extends JpaRepository<BatchExecution, Long> {
    List<BatchExecution> findByBusinessDate(LocalDate businessDate);
    Optional<BatchExecution> findByBatchJob_JobCodeAndBusinessDate(String jobCode, LocalDate businessDate);
    Optional<BatchExecution> findByBatchJob_IdAndBusinessDate(Long jobId, LocalDate businessDate);
    Optional<BatchExecution> findByCorrelationId(String correlationId);
}

