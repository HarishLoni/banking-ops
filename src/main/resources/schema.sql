-- ============================================================================
-- AI Banking Operations Copilot - Database Schema (PostgreSQL)
-- Milestone 1: Plain SQL Schema (Liquibase Cutover in Step 1.4)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SLICE 1: Core Banking Operations Pipeline (Feeds -> Batch Jobs -> Reports)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS data_feed (
    id              BIGSERIAL PRIMARY KEY,
    feed_code       VARCHAR(64)  NOT NULL UNIQUE,
    feed_name       VARCHAR(150) NOT NULL,
    source_system   VARCHAR(100) NOT NULL,
    expected_by_utc TIME         NOT NULL,
    criticality     VARCHAR(20)  NOT NULL CHECK (criticality IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feed_execution (
    id              BIGSERIAL PRIMARY KEY,
    feed_id         BIGINT       NOT NULL REFERENCES data_feed(id),
    business_date   DATE         NOT NULL,
    correlation_id  VARCHAR(64)  NOT NULL,
    status          VARCHAR(20)  NOT NULL CHECK (status IN ('RECEIVED', 'DELAYED', 'MISSING', 'CORRUPTED', 'VALIDATED')),
    record_count    INTEGER      DEFAULT 0,
    file_name       VARCHAR(255),
    error_code      VARCHAR(64),
    error_message   TEXT,
    arrived_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS batch_job (
    id              BIGSERIAL PRIMARY KEY,
    job_code        VARCHAR(64)  NOT NULL UNIQUE,
    job_name        VARCHAR(150) NOT NULL,
    module_name     VARCHAR(64)  NOT NULL,
    upstream_job_id BIGINT       REFERENCES batch_job(id),
    required_feed_id BIGINT      REFERENCES data_feed(id),
    sla_minutes     INTEGER      NOT NULL DEFAULT 30,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS batch_execution (
    id              BIGSERIAL PRIMARY KEY,
    job_id          BIGINT       NOT NULL REFERENCES batch_job(id),
    business_date   DATE         NOT NULL,
    correlation_id  VARCHAR(64)  NOT NULL,
    status          VARCHAR(20)  NOT NULL CHECK (status IN ('RUNNING', 'COMPLETED', 'FAILED', 'TIMED_OUT', 'SKIPPED')),
    records_processed INTEGER    DEFAULT 0,
    records_failed    INTEGER    DEFAULT 0,
    exit_code       VARCHAR(64),
    error_summary   TEXT,
    started_at      TIMESTAMPTZ  NOT NULL,
    ended_at        TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS report_definition (
    id              BIGSERIAL PRIMARY KEY,
    report_code     VARCHAR(64)  NOT NULL UNIQUE,
    report_name     VARCHAR(150) NOT NULL,
    category        VARCHAR(64)  NOT NULL,
    depends_on_job_id BIGINT     NOT NULL REFERENCES batch_job(id),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS report_execution (
    id              BIGSERIAL PRIMARY KEY,
    report_id       BIGINT         NOT NULL REFERENCES report_definition(id),
    business_date   DATE           NOT NULL,
    correlation_id  VARCHAR(64)    NOT NULL,
    status          VARCHAR(20)    NOT NULL CHECK (status IN ('GENERATED', 'FAILED', 'MISMATCH', 'PENDING')),
    expected_total  NUMERIC(18, 2),
    actual_total    NUMERIC(18, 2),
    failure_reason  TEXT,
    started_at      TIMESTAMPTZ    NOT NULL,
    completed_at    TIMESTAMPTZ
);

-- ----------------------------------------------------------------------------
-- SLICE 2: Operational Transactions, Structured Logs, Incident Management,
--          and AI Investigation Dossier
-- ----------------------------------------------------------------------------

-- Transaction processing table: using bank_transaction to prevent reserved keyword collision
CREATE TABLE IF NOT EXISTS bank_transaction (
    id                    BIGSERIAL PRIMARY KEY,
    transaction_reference VARCHAR(64)    NOT NULL UNIQUE,
    correlation_id        VARCHAR(64)    NOT NULL,
    business_date         DATE           NOT NULL,
    source_account        VARCHAR(34)    NOT NULL,
    destination_account   VARCHAR(34)    NOT NULL,
    amount                NUMERIC(18, 2) NOT NULL,
    currency              VARCHAR(3)     NOT NULL DEFAULT 'USD',
    transaction_type      VARCHAR(32)    NOT NULL,
    status                VARCHAR(20)    NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REVERSED')),
    error_code            VARCHAR(64),
    error_message         TEXT,
    channel               VARCHAR(32)    NOT NULL,
    created_at            TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ
);

-- Audit trail for state transitions of high-value or failed banking transactions
CREATE TABLE IF NOT EXISTS transaction_event (
    id             BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT      NOT NULL REFERENCES bank_transaction(id) ON DELETE CASCADE,
    from_status    VARCHAR(20),
    to_status      VARCHAR(20) NOT NULL,
    event_name     VARCHAR(64) NOT NULL,
    details        TEXT,
    occurred_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- High-throughput structured application logs across microservices and batch jobs
CREATE TABLE IF NOT EXISTS application_log (
    id             BIGSERIAL PRIMARY KEY,
    correlation_id VARCHAR(64) NOT NULL,
    service_name   VARCHAR(64) NOT NULL,
    log_level      VARCHAR(10) NOT NULL CHECK (log_level IN ('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
    logger_name    VARCHAR(255),
    error_code     VARCHAR(64),
    message        TEXT        NOT NULL,
    stack_trace    TEXT,
    logged_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Operational incident tracking entity
CREATE TABLE IF NOT EXISTS incident (
    id                 BIGSERIAL PRIMARY KEY,
    incident_number    VARCHAR(32) NOT NULL UNIQUE,
    title              VARCHAR(200) NOT NULL,
    severity           VARCHAR(10) NOT NULL CHECK (severity IN ('P1', 'P2', 'P3', 'P4')),
    status             VARCHAR(20) NOT NULL CHECK (status IN ('OPEN', 'INVESTIGATING', 'MITIGATED', 'RESOLVED', 'CLOSED')),
    category           VARCHAR(64) NOT NULL,
    correlation_id     VARCHAR(64),
    detected_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    mitigated_at       TIMESTAMPTZ,
    resolved_at        TIMESTAMPTZ,
    root_cause_summary TEXT
);

-- Timeline of triage actions, runbook executions, and status transitions
CREATE TABLE IF NOT EXISTS incident_event (
    id           BIGSERIAL PRIMARY KEY,
    incident_id  BIGINT      NOT NULL REFERENCES incident(id) ON DELETE CASCADE,
    event_type   VARCHAR(32) NOT NULL CHECK (event_type IN ('ALERT_TRIGGERED', 'SEV_ESCALATED', 'RUNBOOK_EXECUTED', 'STATUS_CHANGE', 'NOTE_ADDED')),
    description  TEXT        NOT NULL,
    performed_by VARCHAR(64) NOT NULL,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Copilot investigation session (human-triggered or automated triage)
CREATE TABLE IF NOT EXISTS investigation (
    id                    BIGSERIAL PRIMARY KEY,
    investigation_number  VARCHAR(32) NOT NULL UNIQUE,
    incident_id           BIGINT      REFERENCES incident(id),
    query_prompt          TEXT        NOT NULL,
    status                VARCHAR(20) NOT NULL CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED')),
    root_cause_hypothesis TEXT,
    confidence_score      NUMERIC(3, 2),
    recommended_action    TEXT,
    started_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at          TIMESTAMPTZ
);

-- Auditable evidence chain: strict separation between confirmed facts and AI hypotheses
CREATE TABLE IF NOT EXISTS investigation_evidence (
    id               BIGSERIAL PRIMARY KEY,
    investigation_id BIGINT      NOT NULL REFERENCES investigation(id) ON DELETE CASCADE,
    evidence_type    VARCHAR(32) NOT NULL CHECK (evidence_type IN ('BATCH_EXECUTION', 'FEED_EXECUTION', 'LOG_RECORD', 'TRANSACTION_AGGREGATE', 'RUNBOOK_CITATION')),
    source_table     VARCHAR(64),
    source_id        BIGINT,
    correlation_id   VARCHAR(64),
    summary          TEXT        NOT NULL,
    raw_payload      TEXT,
    captured_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- INDEXING STRATEGY: High-Throughput Point Lookups & Analytical Joins
-- ----------------------------------------------------------------------------

-- Slice 1 Indexes
CREATE INDEX IF NOT EXISTS idx_feed_exec_feed_id        ON feed_execution(feed_id);
CREATE INDEX IF NOT EXISTS idx_feed_exec_business_date  ON feed_execution(business_date);
CREATE INDEX IF NOT EXISTS idx_feed_exec_correlation_id ON feed_execution(correlation_id);

CREATE INDEX IF NOT EXISTS idx_batch_job_upstream       ON batch_job(upstream_job_id);
CREATE INDEX IF NOT EXISTS idx_batch_job_feed           ON batch_job(required_feed_id);
CREATE INDEX IF NOT EXISTS idx_batch_exec_job_date      ON batch_execution(job_id, business_date);
CREATE INDEX IF NOT EXISTS idx_batch_exec_correlation_id ON batch_execution(correlation_id);

CREATE INDEX IF NOT EXISTS idx_report_def_job           ON report_definition(depends_on_job_id);
CREATE INDEX IF NOT EXISTS idx_report_exec_report_date  ON report_execution(report_id, business_date);
CREATE INDEX IF NOT EXISTS idx_report_exec_correlation_id ON report_execution(correlation_id);

-- Slice 2 Indexes
CREATE INDEX IF NOT EXISTS idx_bank_txn_business_date   ON bank_transaction(business_date);
CREATE INDEX IF NOT EXISTS idx_bank_txn_correlation_id  ON bank_transaction(correlation_id);
CREATE INDEX IF NOT EXISTS idx_bank_txn_status_error    ON bank_transaction(status, error_code);
CREATE INDEX IF NOT EXISTS idx_bank_txn_source_account  ON bank_transaction(source_account);
CREATE INDEX IF NOT EXISTS idx_txn_event_txn_id         ON transaction_event(transaction_id);

CREATE INDEX IF NOT EXISTS idx_app_log_correlation_id   ON application_log(correlation_id);
CREATE INDEX IF NOT EXISTS idx_app_log_level_logged_at  ON application_log(log_level, logged_at);
CREATE INDEX IF NOT EXISTS idx_app_log_service_date     ON application_log(service_name, logged_at);

CREATE INDEX IF NOT EXISTS idx_incident_correlation_id  ON incident(correlation_id);
CREATE INDEX IF NOT EXISTS idx_incident_status_severity ON incident(status, severity);
CREATE INDEX IF NOT EXISTS idx_incident_event_incident_id ON incident_event(incident_id);

CREATE INDEX IF NOT EXISTS idx_investigation_incident_id ON investigation(incident_id);
CREATE INDEX IF NOT EXISTS idx_investigation_evidence_inv_id ON investigation_evidence(investigation_id);

