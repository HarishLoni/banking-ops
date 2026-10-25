package com.ops.banking_ops_copilot.monitoring.repository;

import com.ops.banking_ops_copilot.monitoring.entity.ReportExecution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReportExecutionRepository extends JpaRepository<ReportExecution, Long> {
    List<ReportExecution> findByBusinessDate(LocalDate businessDate);
    Optional<ReportExecution> findByReportDefinition_ReportCodeAndBusinessDate(String reportCode, LocalDate businessDate);
    Optional<ReportExecution> findByCorrelationId(String correlationId);
    List<ReportExecution> findByBusinessDateAndStatus(LocalDate businessDate, String status);
}

