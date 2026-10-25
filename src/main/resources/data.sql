-- ============================================================================
-- AI Banking Operations Copilot - Deterministic Seed Scenarios (PostgreSQL)
-- Milestone 1: Step 1.2
-- 5 Repeatable Banking Operations Failure Scenarios
-- ============================================================================

-- Clean reload for deterministic testing across restarts
TRUNCATE TABLE 
    investigation_evidence,
    investigation,
    incident_event,
    incident,
    application_log,
    transaction_event,
    bank_transaction,
    report_execution,
    report_definition,
    batch_execution,
    batch_job,
    feed_execution,
    data_feed
RESTART IDENTITY CASCADE;

-- ----------------------------------------------------------------------------
-- MASTER DATA: Data Feeds, Batch Jobs, and Report Definitions
-- ----------------------------------------------------------------------------

-- Master Data Feeds
INSERT INTO data_feed (id, feed_code, feed_name, source_system, expected_by_utc, criticality) VALUES
(1, 'TREASURY_FX_RATES', 'Treasury Daily FX Fixings', 'REUTERS_MARKET_FEED', '04:00:00', 'CRITICAL'),
(2, 'GL_EOD_BALANCES', 'General Ledger End of Day Balances', 'CORE_BANKING_CBS', '23:30:00', 'HIGH'),
(3, 'SWIFT_INBOUND_MESSAGES', 'SWIFT MT103 Inbound Transactions', 'SWIFT_GATEWAY', '22:00:00', 'CRITICAL');

-- Master Batch Jobs (Hierarchy: LCR depends on CASH_FLOW; Jobs link to required feeds)
INSERT INTO batch_job (id, job_code, job_name, module_name, upstream_job_id, required_feed_id, sla_minutes) VALUES
(1, 'CASH_FLOW_AGGREGATION_JOB', 'Cash Flow Ingestion and Aggregation', 'TREASURY', NULL, 1, 30),
(2, 'LCR_CALCULATION_JOB', 'Liquidity Coverage Ratio Calculation Engine', 'RISK', 1, NULL, 45),
(3, 'TREASURY_VALUATION_JOB', 'Mark to Market Treasury Valuation', 'TREASURY', NULL, 1, 30),
(4, 'SWIFT_OUTBOUND_DISPATCH_JOB', 'SWIFT High Value Outbound Dispatcher', 'PAYMENTS', NULL, 3, 45),
(5, 'GL_POSTING_RECON_JOB', 'General Ledger Balance Reconciliation Job', 'FINANCE', NULL, 2, 60);

-- Master Regulatory & Reconciliation Reports
INSERT INTO report_definition (id, report_code, report_name, category, depends_on_job_id) VALUES
(1, 'DAILY_LCR_REPORT', 'Daily Liquidity Coverage Ratio Regulatory Report', 'REGULATORY_LIQUIDITY', 2),
(2, 'EOD_GL_RECON_REPORT', 'End of Day General Ledger Reconciliation Report', 'FINANCIAL_RECONCILIATION', 5),
(3, 'TREASURY_POSITION_REPORT', 'Treasury Net FX Exposure Report', 'TREASURY_RISK', 3);

-- Synchronize master table sequence generators
SELECT setval('data_feed_id_seq', (SELECT MAX(id) FROM data_feed));
SELECT setval('batch_job_id_seq', (SELECT MAX(id) FROM batch_job));
SELECT setval('report_definition_id_seq', (SELECT MAX(id) FROM report_definition));

-- ============================================================================
-- SCENARIO 1: Upstream Batch Job Failure
-- Investigation Query: "Why did the liquidity report (DAILY_LCR_REPORT) fail on 2026-10-24?"
-- Root Cause: LCR_CALCULATION_JOB crashed with Java OOM during asset matrix inversion.
-- ============================================================================

-- Step 1: Upstream batch cash flow succeeded
INSERT INTO batch_execution (job_id, business_date, correlation_id, status, records_processed, records_failed, exit_code, error_summary, started_at, ended_at)
VALUES (1, '2026-10-24', 'CORR-LCR-20261024-001', 'COMPLETED', 150000, 0, 'SUCCESS', 'Completed cash flow aggregation successfully',
        '2026-10-24 04:15:00+00', '2026-10-24 04:42:10+00');

-- Step 2: LCR calculation job failed with OutOfMemory
INSERT INTO batch_execution (job_id, business_date, correlation_id, status, records_processed, records_failed, exit_code, error_summary, started_at, ended_at)
VALUES (2, '2026-10-24', 'CORR-LCR-20261024-001', 'FAILED', 42000, 120, 'ERR_OUT_OF_MEMORY',
        'Java heap space during matrix inversion of unencumbered asset reserves',
        '2026-10-24 05:00:00+00', '2026-10-24 05:32:15+00');

-- Step 3: Dependent report failed immediately
INSERT INTO report_execution (report_id, business_date, correlation_id, status, expected_total, actual_total, failure_reason, started_at, completed_at)
VALUES (1, '2026-10-24', 'CORR-LCR-20261024-001', 'FAILED', 1250000000.00, NULL,
        'Upstream batch job LCR_CALCULATION_JOB failed with exit code ERR_OUT_OF_MEMORY',
        '2026-10-24 05:33:00+00', '2026-10-24 05:33:05+00');

-- Logs for Scenario 1
INSERT INTO application_log (correlation_id, service_name, log_level, logger_name, error_code, message, stack_trace, logged_at) VALUES
('CORR-LCR-20261024-001', 'batch-orchestrator', 'INFO', 'com.ops.batch.JobLauncher', NULL,
 'Starting scheduled execution of LCR_CALCULATION_JOB for business date 2026-10-24', NULL, '2026-10-24 05:00:01+00'),
('CORR-LCR-20261024-001', 'risk-engine', 'ERROR', 'com.ops.engine.LcrMatrixSolver', 'ERR_OUT_OF_MEMORY',
 'Fatal exception during LCR matrix computation: java.lang.OutOfMemoryError: Java heap space',
 'java.lang.OutOfMemoryError: Java heap space\n\tat com.ops.engine.LcrMatrixSolver.invert(LcrMatrixSolver.java:142)\n\tat com.ops.engine.LcrService.compute(LcrService.java:88)',
 '2026-10-24 05:32:14+00'),
('CORR-LCR-20261024-001', 'report-generator', 'ERROR', 'com.ops.report.RegulatoryReportPublisher', 'UPSTREAM_DEPENDENCY_FAILED',
 'Aborting DAILY_LCR_REPORT. Required upstream dataset from LCR_CALCULATION_JOB is marked FAILED.', NULL, '2026-10-24 05:33:04+00');

-- Incident ticket for Scenario 1
INSERT INTO incident (id, incident_number, title, severity, status, category, correlation_id, detected_at, root_cause_summary) VALUES
(1, 'INC-20261024-001', 'DAILY_LCR_REPORT generation failed due to OOM in LCR_CALCULATION_JOB', 'P1', 'OPEN', 'BATCH_PIPELINE', 'CORR-LCR-20261024-001',
 '2026-10-24 05:35:00+00', 'LCR_CALCULATION_JOB exceeded container JVM memory limit (4GB) during asset matrix inversion.');

INSERT INTO incident_event (incident_id, event_type, description, performed_by, occurred_at) VALUES
(1, 'ALERT_TRIGGERED', 'Automated SLA breach alert fired: DAILY_LCR_REPORT not published by 05:30 UTC', 'SYSTEM', '2026-10-24 05:35:00+00'),
(1, 'SEV_ESCALATED', 'Severity auto-escalated to P1 due to regulatory compliance SLA penalty risk', 'OPS_WATCHDOG', '2026-10-24 05:36:00+00');

-- ============================================================================
-- SCENARIO 2: Missing Input Data Feed
-- Investigation Query: "Why is the Treasury Net FX Exposure Report missing / job skipped?"
-- Root Cause: Reuters market FX rate feed file was never delivered to SFTP by cutoff.
-- ============================================================================

INSERT INTO feed_execution (feed_id, business_date, correlation_id, status, record_count, file_name, error_code, error_message, arrived_at, completed_at)
VALUES (1, '2026-10-24', 'CORR-FEED-FX-20261024', 'MISSING', 0, 'fx_rates_20261024.csv', 'FEED_FILE_NOT_FOUND',
        'SFTP inbound file fx_rates_20261024.csv not found at sftp://marketfeed.bank.internal/inbound by 04:30:00 UTC cutoff',
        NULL, '2026-10-24 04:30:00+00');

INSERT INTO batch_execution (job_id, business_date, correlation_id, status, records_processed, records_failed, exit_code, error_summary, started_at, ended_at)
VALUES (3, '2026-10-24', 'CORR-FEED-FX-20261024', 'SKIPPED', 0, 0, 'PRECONDITION_FAILED',
        'Mandatory market data feed TREASURY_FX_RATES is MISSING for business date 2026-10-24',
        '2026-10-24 04:31:00+00', '2026-10-24 04:31:02+00');

INSERT INTO report_execution (report_id, business_date, correlation_id, status, expected_total, actual_total, failure_reason, started_at, completed_at)
VALUES (3, '2026-10-24', 'CORR-FEED-FX-20261024', 'PENDING', NULL, NULL,
        'Waiting for upstream TREASURY_VALUATION_JOB to complete',
        '2026-10-24 04:31:10+00', NULL);

INSERT INTO application_log (correlation_id, service_name, log_level, logger_name, error_code, message, stack_trace, logged_at) VALUES
('CORR-FEED-FX-20261024', 'feed-ingestion-service', 'WARN', 'com.ops.feed.SftpPoller', 'FILE_POLL_RETRY',
 'File fx_rates_20261024.csv not present on remote SFTP host. Poll attempt 5 of 5.', NULL, '2026-10-24 04:25:00+00'),
('CORR-FEED-FX-20261024', 'feed-ingestion-service', 'ERROR', 'com.ops.feed.FeedCutoffWatchdog', 'FEED_FILE_NOT_FOUND',
 'SLA Cutoff 04:30:00 UTC exceeded. Marking feed TREASURY_FX_RATES as MISSING.', NULL, '2026-10-24 04:30:01+00'),
('CORR-FEED-FX-20261024', 'batch-orchestrator', 'ERROR', 'com.ops.batch.PreconditionEvaluator', 'PRECONDITION_FAILED',
 'Job TREASURY_VALUATION_JOB skipped because prerequisite feed TREASURY_FX_RATES status is MISSING.', NULL, '2026-10-24 04:31:01+00');

INSERT INTO incident (id, incident_number, title, severity, status, category, correlation_id, detected_at, root_cause_summary) VALUES
(2, 'INC-20261024-002', 'Market feed TREASURY_FX_RATES missing at SLA cutoff', 'P2', 'OPEN', 'FEED_FAILURE', 'CORR-FEED-FX-20261024',
 '2026-10-24 04:32:00+00', 'External vendor Reuters SFTP endpoint failed to deliver fx_rates_20261024.csv by 04:30 UTC.');

INSERT INTO incident_event (incident_id, event_type, description, performed_by, occurred_at) VALUES
(2, 'ALERT_TRIGGERED', 'Feed SLA watchdog detected missing feed TREASURY_FX_RATES', 'SYSTEM', '2026-10-24 04:32:00+00');

-- ============================================================================
-- SCENARIO 3: Increased Transaction Failures (Shared Error Code Spike)
-- Investigation Query: "Why did payment transactions spike with failures around 09:15 UTC on 2026-10-24?"
-- Root Cause: Core banking CBS posting interface connection pool timeout (504).
-- ============================================================================

INSERT INTO bank_transaction (id, transaction_reference, correlation_id, business_date, source_account, destination_account, amount, currency, transaction_type, status, error_code, error_message, channel, created_at) VALUES
(1,  'TXN-20261024-101', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-GB-10928374', 'ACC-US-99283411',  4500.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:12:01+00'),
(2,  'TXN-20261024-102', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-DE-44819203', 'ACC-US-33192847', 12500.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:12:35+00'),
(3,  'TXN-20261024-103', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-FR-88291039', 'ACC-US-88491029',   750.50, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:13:10+00'),
(4,  'TXN-20261024-104', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-US-11029384', 'ACC-SG-55019283', 35000.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:13:45+00'),
(5,  'TXN-20261024-105', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-SG-77391028', 'ACC-GB-10928374',  2200.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:14:12+00'),
(6,  'TXN-20261024-106', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-US-99102938', 'ACC-DE-44819203',  8900.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:14:48+00'),
(7,  'TXN-20261024-107', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-GB-22910293', 'ACC-FR-88291039', 15400.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:15:20+00'),
(8,  'TXN-20261024-108', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-DE-66102938', 'ACC-US-11029384',   450.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:15:55+00'),
(9,  'TXN-20261024-109', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-US-33910293', 'ACC-SG-77391028', 50000.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:16:30+00'),
(10, 'TXN-20261024-110', 'CORR-TXN-SPIKE-20261024', '2026-10-24', 'ACC-SG-11029384', 'ACC-GB-22910293',  6300.00, 'USD', 'PAYMENT', 'FAILED', 'CORE_BANKING_TIMEOUT', 'Connection pool exhausted while calling Core Banking Posting API (504 Gateway Timeout)', 'API_GATEWAY', '2026-10-24 09:17:05+00'),
-- Successful transactions on the same day for contrast
(11, 'TXN-20261024-001', 'CORR-TXN-HEALTHY-001',   '2026-10-24', 'ACC-US-55019283', 'ACC-GB-10928374',  1500.00, 'USD', 'PAYMENT', 'SUCCESS', NULL, NULL, 'ONLINE_BANKING', '2026-10-24 08:30:00+00'),
(12, 'TXN-20261024-002', 'CORR-TXN-HEALTHY-002',   '2026-10-24', 'ACC-DE-33192847', 'ACC-US-99283411',  3200.00, 'USD', 'PAYMENT', 'SUCCESS', NULL, NULL, 'ONLINE_BANKING', '2026-10-24 08:45:00+00');

-- Transaction events for failure tracking
INSERT INTO transaction_event (transaction_id, from_status, to_status, event_name, details, occurred_at)
SELECT id, 'PENDING', 'FAILED', 'POSTING_TIMEOUT', 'Timeout after 10000ms connecting to CBS host cluster ip-10-0-4-12', created_at + interval '10 seconds'
FROM bank_transaction
WHERE status = 'FAILED' AND correlation_id = 'CORR-TXN-SPIKE-20261024';

-- Logs for Scenario 3
INSERT INTO application_log (correlation_id, service_name, log_level, logger_name, error_code, message, stack_trace, logged_at) VALUES
('CORR-TXN-SPIKE-20261024', 'payment-gateway', 'ERROR', 'com.ops.payment.CoreBankingClient', 'CORE_BANKING_TIMEOUT',
 'HTTP 504 Gateway Timeout from Core Banking API endpoint https://cbs.internal.bank/api/v2/postings',
 'com.ops.exception.RemoteServiceException: 504 Gateway Timeout\n\tat com.ops.client.CbsClient.postLedger(CbsClient.java:94)',
 '2026-10-24 09:12:11+00'),
('CORR-TXN-SPIKE-20261024', 'payment-gateway', 'ERROR', 'com.zaxxer.hikari.pool.HikariPool', 'POOL_EXHAUSTED',
 'HikariPool-1 - Connection is not available, request timed out after 30000ms (total=50, active=50, idle=0, waiting=18)', NULL,
 '2026-10-24 09:14:00+00'),
('CORR-TXN-SPIKE-20261024', 'payment-service', 'WARN', 'com.ops.payment.CircuitBreaker', 'CIRCUIT_BREAKER_OPEN',
 'CircuitBreaker "cbsPostingService" changed state from CLOSED to OPEN (failure rate: 84.5% > threshold: 50.0%)', NULL,
 '2026-10-24 09:16:00+00');

-- Incident for Scenario 3
INSERT INTO incident (id, incident_number, title, severity, status, category, correlation_id, detected_at, root_cause_summary) VALUES
(3, 'INC-20261024-003', 'Payment transaction failure rate spike > 80% (CORE_BANKING_TIMEOUT)', 'P1', 'INVESTIGATING', 'TRANSACTION_SPIKE', 'CORR-TXN-SPIKE-20261024',
 '2026-10-24 09:18:00+00', 'Core Banking posting connection pool saturated resulting in cascading 504 gateway timeouts.');

INSERT INTO incident_event (incident_id, event_type, description, performed_by, occurred_at) VALUES
(3, 'ALERT_TRIGGERED', 'Anomaly detector flagged failure rate surge: 10 failed payments in 5 minutes', 'ANOMALY_WATCHDOG', '2026-10-24 09:18:00+00'),
(3, 'STATUS_CHANGE', 'Incident assigned to Payments On-Call and triage initiated', 'OPS_LEAD', '2026-10-24 09:20:00+00');

-- ============================================================================
-- SCENARIO 4: Simulated Dependency Timeout (Downstream SWIFT Gateway SLA Breach)
-- Investigation Query: "Why did SWIFT_OUTBOUND_DISPATCH_JOB fail with TIMED_OUT?"
-- Root Cause: SWIFT Alliance Lite2 gateway became unresponsive; watchdog aborted job at 45 min SLA.
-- ============================================================================

INSERT INTO batch_execution (job_id, business_date, correlation_id, status, records_processed, records_failed, exit_code, error_summary, started_at, ended_at)
VALUES (4, '2026-10-24', 'CORR-SWIFT-20261024-001', 'TIMED_OUT', 850, 150, 'ERR_GATEWAY_TIMEOUT',
        'Exceeded SLA limit of 45 minutes waiting for SWIFT Alliance Lite2 gateway acknowledgement',
        '2026-10-24 22:30:00+00', '2026-10-24 23:15:30+00');

INSERT INTO application_log (correlation_id, service_name, log_level, logger_name, error_code, message, stack_trace, logged_at) VALUES
('CORR-SWIFT-20261024-001', 'swift-dispatch-service', 'INFO', 'com.ops.swift.OutboundDispatcher', NULL,
 'Started batch dispatching 1000 MT103 credit transfer messages to SWIFT network', NULL, '2026-10-24 22:30:01+00'),
('CORR-SWIFT-20261024-001', 'swift-connector', 'WARN', 'com.ops.swift.AllianceLiteClient', 'SOCKET_TIMEOUT',
 'Socket read timed out after 60000ms while awaiting FIN ACK from SWIFT gateway 198.18.0.5:10022. Retry 3 of 3.', NULL, '2026-10-24 23:05:12+00'),
('CORR-SWIFT-20261024-001', 'batch-orchestrator', 'ERROR', 'com.ops.batch.JobTimeoutWatchdog', 'ERR_GATEWAY_TIMEOUT',
 'Job SWIFT_OUTBOUND_DISPATCH_JOB execution killed: running duration 45m 30s exceeded maximum SLA threshold of 45 minutes', NULL,
 '2026-10-24 23:15:30+00');

INSERT INTO incident (id, incident_number, title, severity, status, category, correlation_id, detected_at, root_cause_summary) VALUES
(4, 'INC-20261024-004', 'SWIFT outbound batch dispatcher timed out (SLA breach)', 'P2', 'OPEN', 'BATCH_PIPELINE', 'CORR-SWIFT-20261024-001',
 '2026-10-24 23:16:00+00', 'SWIFT Alliance gateway socket connection timed out causing job SLA breach.');

INSERT INTO incident_event (incident_id, event_type, description, performed_by, occurred_at) VALUES
(4, 'ALERT_TRIGGERED', 'Batch job watchdog terminated SWIFT_OUTBOUND_DISPATCH_JOB after 45m SLA expiration', 'SYSTEM', '2026-10-24 23:16:00+00');

-- ============================================================================
-- SCENARIO 5: Report-Total Mismatch (Financial Reconciliation Imbalance)
-- Investigation Query: "Why is EOD_GL_RECON_REPORT marked MISMATCH on 2026-10-24?"
-- Root Cause: A $50,000 imbalance between GL control account and subledger caused by unposted suspense batch.
-- ============================================================================

INSERT INTO batch_execution (job_id, business_date, correlation_id, status, records_processed, records_failed, exit_code, error_summary, started_at, ended_at)
VALUES (5, '2026-10-24', 'CORR-GL-RECON-20261024', 'COMPLETED', 320000, 0, 'SUCCESS',
        'GL reconciliation batch processed all ledger entries; trial balance mismatch detected',
        '2026-10-24 23:35:00+00', '2026-10-24 23:55:10+00');

INSERT INTO report_execution (report_id, business_date, correlation_id, status, expected_total, actual_total, failure_reason, started_at, completed_at)
VALUES (2, '2026-10-24', 'CORR-GL-RECON-20261024', 'MISMATCH', 145025000.00, 144975000.00,
        'Variance detected between GL control account 1001-000 and sub-ledger trial balance. Delta: -50000.00 USD',
        '2026-10-24 23:55:15+00', '2026-10-24 23:58:00+00');

INSERT INTO application_log (correlation_id, service_name, log_level, logger_name, error_code, message, stack_trace, logged_at) VALUES
('CORR-GL-RECON-20261024', 'gl-recon-engine', 'INFO', 'com.ops.finance.ReconciliationRunner', NULL,
 'Starting EOD trial balance reconciliation for General Ledger control account 1001-000', NULL, '2026-10-24 23:35:01+00'),
('CORR-GL-RECON-20261024', 'gl-recon-engine', 'WARN', 'com.ops.finance.BalanceComparator', 'GL_VARIANCE_DETECTED',
 'Variance detected in asset class COMMERCIAL_LOANS: Control Total = 145,025,000.00 USD, Subledger Total = 144,975,000.00 USD, Variance = -50,000.00 USD', NULL,
 '2026-10-24 23:56:40+00'),
('CORR-GL-RECON-20261024', 'gl-recon-engine', 'ERROR', 'com.ops.finance.SuspenseDetector', 'UNPOSTED_SUSPENSE_BATCH',
 'Identified unposted suspense batch GL-BATCH-9941 containing unapplied adjustments of exactly 50,000.00 USD in status PENDING_REVIEW', NULL,
 '2026-10-24 23:57:30+00');

INSERT INTO incident (id, incident_number, title, severity, status, category, correlation_id, detected_at, root_cause_summary) VALUES
(5, 'INC-20261024-005', 'EOD GL reconciliation report balance mismatch (-50,000.00 USD delta)', 'P1', 'OPEN', 'REPORT_MISMATCH', 'CORR-GL-RECON-20261024',
 '2026-10-24 23:59:00+00', 'Trial balance out of balance by $50,000 due to unposted suspense batch GL-BATCH-9941.');

INSERT INTO incident_event (incident_id, event_type, description, performed_by, occurred_at) VALUES
(5, 'ALERT_TRIGGERED', 'EOD reconciliation variance alert triggered: delta exceeds materiality tolerance of 0.00 USD', 'FINANCE_WATCHDOG', '2026-10-24 23:59:00+00');

-- Synchronize sequences for transactional tables
SELECT setval('bank_transaction_id_seq', (SELECT COALESCE(MAX(id), 1) FROM bank_transaction));
SELECT setval('transaction_event_id_seq', (SELECT COALESCE(MAX(id), 1) FROM transaction_event));
SELECT setval('application_log_id_seq', (SELECT COALESCE(MAX(id), 1) FROM application_log));
SELECT setval('incident_id_seq', (SELECT COALESCE(MAX(id), 1) FROM incident));
SELECT setval('incident_event_id_seq', (SELECT COALESCE(MAX(id), 1) FROM incident_event));
SELECT setval('feed_execution_id_seq', (SELECT COALESCE(MAX(id), 1) FROM feed_execution));
SELECT setval('batch_execution_id_seq', (SELECT COALESCE(MAX(id), 1) FROM batch_execution));
SELECT setval('report_execution_id_seq', (SELECT COALESCE(MAX(id), 1) FROM report_execution));

