-- ============================================================================
-- AI Banking Operations Copilot - Diagnostic SQL Queries
-- Milestone 1: Step 1.3
-- Run these queries against the 'bank' PostgreSQL database to trace root causes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SCENARIO 1: Upstream Batch Failure Analysis
-- "Why did the daily liquidity report (DAILY_LCR_REPORT) fail on 2026-10-24?"
-- ----------------------------------------------------------------------------
WITH failed_report AS (
    SELECT 
        re.id AS report_exec_id,
        rd.report_code,
        rd.report_name,
        re.business_date,
        re.correlation_id,
        re.status AS report_status,
        re.failure_reason,
        rd.depends_on_job_id
    FROM report_execution re
    JOIN report_definition rd ON re.report_id = rd.id
    WHERE rd.report_code = 'DAILY_LCR_REPORT'
      AND re.business_date = '2026-10-24'
),
batch_status AS (
    SELECT 
        be.id AS batch_exec_id,
        bj.job_code,
        bj.job_name,
        be.status AS batch_status,
        be.exit_code,
        be.error_summary,
        be.records_processed,
        be.records_failed
    FROM batch_execution be
    JOIN batch_job bj ON be.job_id = bj.id
    WHERE be.job_id = (SELECT depends_on_job_id FROM failed_report)
      AND be.business_date = '2026-10-24'
),
root_cause_logs AS (
    SELECT 
        service_name,
        log_level,
        error_code,
        message,
        stack_trace
    FROM application_log
    WHERE correlation_id = (SELECT correlation_id FROM failed_report)
      AND log_level IN ('ERROR', 'FATAL')
)
SELECT 
    r.report_code,
    r.report_status,
    b.job_code AS failed_upstream_job,
    b.batch_status,
    b.exit_code,
    b.error_summary,
    l.service_name,
    l.error_code AS log_error_code,
    l.message AS root_cause_log,
    l.stack_trace
FROM failed_report r
CROSS JOIN batch_status b
LEFT JOIN root_cause_logs l ON true;


-- ----------------------------------------------------------------------------
-- SCENARIO 2: Missing Input Data Feed Analysis
-- "Why is the Treasury Net FX Exposure Report / Valuation Job missing/skipped?"
-- ----------------------------------------------------------------------------
SELECT 
    bj.job_code,
    be.business_date,
    be.status AS batch_status,
    be.error_summary,
    df.feed_code AS required_feed,
    df.source_system,
    df.expected_by_utc,
    fe.status AS feed_status,
    fe.file_name,
    fe.error_code AS feed_error_code,
    fe.error_message,
    inc.incident_number,
    inc.severity AS incident_severity
FROM batch_execution be
JOIN batch_job bj ON be.job_id = bj.id
JOIN data_feed df ON bj.required_feed_id = df.id
LEFT JOIN feed_execution fe 
    ON df.id = fe.feed_id 
   AND fe.business_date = be.business_date
LEFT JOIN incident inc 
    ON inc.correlation_id = be.correlation_id
WHERE bj.job_code = 'TREASURY_VALUATION_JOB'
  AND be.business_date = '2026-10-24';


-- ----------------------------------------------------------------------------
-- SCENARIO 3: Payment Transaction Failure Rate & Error Distribution Spike
-- "Why did payment transactions spike with failures around 09:15 UTC on 2026-10-24?"
-- ----------------------------------------------------------------------------

-- Part A: Aggregate Channel Failure Rates (PostgreSQL FILTER clause)
SELECT 
    business_date,
    channel,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE status = 'SUCCESS') AS successful_count,
    COUNT(*) FILTER (WHERE status = 'FAILED') AS failed_count,
    ROUND(
        (COUNT(*) FILTER (WHERE status = 'FAILED')::NUMERIC / COUNT(*)::NUMERIC) * 100, 
        2
    ) AS failure_rate_percentage
FROM bank_transaction
WHERE business_date = '2026-10-24'
GROUP BY business_date, channel;

-- Part B: Top Error Breakdown & Correlation with Infrastructure Logs
SELECT 
    bt.error_code,
    bt.error_message,
    COUNT(*) AS failure_occurrences,
    MIN(bt.created_at) AS first_failure_at,
    MAX(bt.created_at) AS last_failure_at,
    al.service_name,
    al.message AS infra_error_log
FROM bank_transaction bt
LEFT JOIN application_log al 
    ON al.correlation_id = bt.correlation_id 
   AND al.error_code = 'POOL_EXHAUSTED'
WHERE bt.business_date = '2026-10-24'
  AND bt.status = 'FAILED'
GROUP BY bt.error_code, bt.error_message, al.service_name, al.message;


-- ----------------------------------------------------------------------------
-- SCENARIO 4: Simulated Dependency Timeout (Downstream SWIFT Gateway SLA Breach)
-- "Why did SWIFT_OUTBOUND_DISPATCH_JOB fail with TIMED_OUT on 2026-10-24?"
-- ----------------------------------------------------------------------------
SELECT 
    bj.job_code,
    bj.job_name,
    bj.sla_minutes AS configured_sla_minutes,
    be.started_at,
    be.ended_at,
    ROUND(EXTRACT(EPOCH FROM (be.ended_at - be.started_at)) / 60, 2) AS actual_duration_minutes,
    be.status AS execution_status,
    be.exit_code,
    be.records_processed,
    be.records_failed,
    be.error_summary,
    al.logger_name,
    al.message AS timeout_log_detail
FROM batch_execution be
JOIN batch_job bj ON be.job_id = bj.id
LEFT JOIN application_log al 
    ON al.correlation_id = be.correlation_id 
   AND al.error_code IN ('SOCKET_TIMEOUT', 'ERR_GATEWAY_TIMEOUT')
WHERE bj.job_code = 'SWIFT_OUTBOUND_DISPATCH_JOB'
  AND be.business_date = '2026-10-24';


-- ----------------------------------------------------------------------------
-- SCENARIO 5: Financial Reconciliation Variance & Suspense Discovery
-- "Why is EOD_GL_RECON_REPORT marked MISMATCH on 2026-10-24?"
-- ----------------------------------------------------------------------------
SELECT 
    rd.report_code,
    rd.report_name,
    re.business_date,
    re.status AS report_status,
    re.expected_total,
    re.actual_total,
    (re.actual_total - re.expected_total) AS balance_variance,
    re.failure_reason,
    al.error_code AS suspense_code,
    al.message AS reconciliation_evidence
FROM report_execution re
JOIN report_definition rd ON re.report_id = rd.id
LEFT JOIN application_log al 
    ON al.correlation_id = re.correlation_id 
   AND al.error_code = 'UNPOSTED_SUSPENSE_BATCH'
WHERE rd.report_code = 'EOD_GL_RECON_REPORT'
  AND re.business_date = '2026-10-24';

