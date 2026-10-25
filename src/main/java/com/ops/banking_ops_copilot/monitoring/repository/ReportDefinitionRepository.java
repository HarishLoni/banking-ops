package com.ops.banking_ops_copilot.monitoring.repository;

import com.ops.banking_ops_copilot.monitoring.entity.ReportDefinition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ReportDefinitionRepository extends JpaRepository<ReportDefinition, Long> {
    Optional<ReportDefinition> findByReportCode(String reportCode);
}

