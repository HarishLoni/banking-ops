package com.ops.banking_ops_copilot.monitoring.service;

import com.ops.banking_ops_copilot.monitoring.dto.BatchExecutionResponse;
import com.ops.banking_ops_copilot.monitoring.dto.FeedExecutionResponse;
import com.ops.banking_ops_copilot.monitoring.dto.ReportExecutionResponse;
import com.ops.banking_ops_copilot.monitoring.entity.BatchExecution;
import com.ops.banking_ops_copilot.monitoring.entity.FeedExecution;
import com.ops.banking_ops_copilot.monitoring.entity.ReportExecution;
import com.ops.banking_ops_copilot.monitoring.repository.BatchExecutionRepository;
import com.ops.banking_ops_copilot.monitoring.repository.FeedExecutionRepository;
import com.ops.banking_ops_copilot.monitoring.repository.ReportExecutionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class MonitoringService {

    private final ReportExecutionRepository reportExecutionRepository;
    private final BatchExecutionRepository batchExecutionRepository;
    private final FeedExecutionRepository feedExecutionRepository;

    public MonitoringService(
            ReportExecutionRepository reportExecutionRepository,
            BatchExecutionRepository batchExecutionRepository,
            FeedExecutionRepository feedExecutionRepository) {
        this.reportExecutionRepository = reportExecutionRepository;
        this.batchExecutionRepository = batchExecutionRepository;
        this.feedExecutionRepository = feedExecutionRepository;
    }

    public List<ReportExecutionResponse> getReportsByDate(LocalDate businessDate) {
        return reportExecutionRepository.findByBusinessDate(businessDate)
                .stream()
                .map(this::mapToReportResponse)
                .toList();
    }

    public Optional<ReportExecutionResponse> getReportStatus(String reportCode, LocalDate businessDate) {
        return reportExecutionRepository.findByReportDefinition_ReportCodeAndBusinessDate(reportCode, businessDate)
                .map(this::mapToReportResponse);
    }

    public List<BatchExecutionResponse> getBatchExecutionsByDate(LocalDate businessDate) {
        return batchExecutionRepository.findByBusinessDate(businessDate)
                .stream()
                .map(this::mapToBatchResponse)
                .toList();
    }

    public Optional<BatchExecutionResponse> getBatchStatus(String jobCode, LocalDate businessDate) {
        return batchExecutionRepository.findByBatchJob_JobCodeAndBusinessDate(jobCode, businessDate)
                .map(this::mapToBatchResponse);
    }

    public List<FeedExecutionResponse> getFeedExecutionsByDate(LocalDate businessDate) {
        return feedExecutionRepository.findByBusinessDate(businessDate)
                .stream()
                .map(this::mapToFeedResponse)
                .toList();
    }

    public Optional<FeedExecutionResponse> getFeedStatus(String feedCode, LocalDate businessDate) {
        return feedExecutionRepository.findByDataFeed_FeedCodeAndBusinessDate(feedCode, businessDate)
                .map(this::mapToFeedResponse);
    }

    private ReportExecutionResponse mapToReportResponse(ReportExecution r) {
        BigDecimal variance = null;
        if (r.getExpectedTotal() != null && r.getActualTotal() != null) {
            variance = r.getActualTotal().subtract(r.getExpectedTotal());
        }

        return new ReportExecutionResponse(
                r.getId(),
                r.getReportDefinition().getReportCode(),
                r.getReportDefinition().getReportName(),
                r.getReportDefinition().getCategory(),
                r.getBusinessDate(),
                r.getCorrelationId(),
                r.getStatus(),
                r.getExpectedTotal(),
                r.getActualTotal(),
                variance,
                r.getFailureReason(),
                r.getStartedAt(),
                r.getCompletedAt()
        );
    }

    private BatchExecutionResponse mapToBatchResponse(BatchExecution b) {
        return new BatchExecutionResponse(
                b.getId(),
                b.getBatchJob().getJobCode(),
                b.getBatchJob().getJobName(),
                b.getBatchJob().getModuleName(),
                b.getBusinessDate(),
                b.getCorrelationId(),
                b.getStatus(),
                b.getRecordsProcessed(),
                b.getRecordsFailed(),
                b.getExitCode(),
                b.getErrorSummary(),
                b.getStartedAt(),
                b.getEndedAt()
        );
    }

    private FeedExecutionResponse mapToFeedResponse(FeedExecution f) {
        return new FeedExecutionResponse(
                f.getId(),
                f.getDataFeed().getFeedCode(),
                f.getDataFeed().getFeedName(),
                f.getDataFeed().getSourceSystem(),
                f.getBusinessDate(),
                f.getCorrelationId(),
                f.getStatus(),
                f.getRecordCount(),
                f.getFileName(),
                f.getErrorCode(),
                f.getErrorMessage(),
                f.getArrivedAt(),
                f.getCompletedAt()
        );
    }
}

