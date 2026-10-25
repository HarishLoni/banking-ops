package com.ops.banking_ops_copilot.monitoring.controller;

import com.ops.banking_ops_copilot.monitoring.dto.BatchExecutionResponse;
import com.ops.banking_ops_copilot.monitoring.dto.FeedExecutionResponse;
import com.ops.banking_ops_copilot.monitoring.dto.ReportExecutionResponse;
import com.ops.banking_ops_copilot.monitoring.service.MonitoringService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/monitoring")
public class MonitoringController {

    private final MonitoringService monitoringService;

    public MonitoringController(MonitoringService monitoringService) {
        this.monitoringService = monitoringService;
    }

    @GetMapping("/reports")
    public ResponseEntity<List<ReportExecutionResponse>> getReports(
            @RequestParam(name = "date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(monitoringService.getReportsByDate(date));
    }

    @GetMapping("/reports/{reportCode}")
    public ResponseEntity<ReportExecutionResponse> getReportStatus(
            @PathVariable String reportCode,
            @RequestParam(name = "date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return monitoringService.getReportStatus(reportCode, date)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/batch-jobs")
    public ResponseEntity<List<BatchExecutionResponse>> getBatchExecutions(
            @RequestParam(name = "date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(monitoringService.getBatchExecutionsByDate(date));
    }

    @GetMapping("/batch-jobs/{jobCode}")
    public ResponseEntity<BatchExecutionResponse> getBatchStatus(
            @PathVariable String jobCode,
            @RequestParam(name = "date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return monitoringService.getBatchStatus(jobCode, date)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/feeds")
    public ResponseEntity<List<FeedExecutionResponse>> getFeedExecutions(
            @RequestParam(name = "date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(monitoringService.getFeedExecutionsByDate(date));
    }

    @GetMapping("/feeds/{feedCode}")
    public ResponseEntity<FeedExecutionResponse> getFeedStatus(
            @PathVariable String feedCode,
            @RequestParam(name = "date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return monitoringService.getFeedStatus(feedCode, date)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}

