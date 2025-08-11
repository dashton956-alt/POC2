-- Database schema for Syslog MCP Analysis workflow
-- Run this SQL in your PostgreSQL database to create the required tables

-- Create syslog_analysis table to store analysis results
CREATE TABLE IF NOT EXISTS syslog_analysis (
    id SERIAL PRIMARY KEY,
    syslog_id VARCHAR(255) UNIQUE NOT NULL,
    hostname VARCHAR(255) NOT NULL,
    severity INTEGER NOT NULL,
    facility INTEGER NOT NULL,
    raw_message TEXT NOT NULL,
    mcp_analysis JSONB NOT NULL,
    recommendations_count INTEGER DEFAULT 0,
    risk_score DECIMAL(3,1) DEFAULT 0.0,
    escalation_required BOOLEAN DEFAULT FALSE,
    auto_remediation_available BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    analysis_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_syslog_analysis_hostname ON syslog_analysis(hostname);
CREATE INDEX IF NOT EXISTS idx_syslog_analysis_severity ON syslog_analysis(severity);
CREATE INDEX IF NOT EXISTS idx_syslog_analysis_risk_score ON syslog_analysis(risk_score);
CREATE INDEX IF NOT EXISTS idx_syslog_analysis_created_at ON syslog_analysis(created_at);
CREATE INDEX IF NOT EXISTS idx_syslog_analysis_escalation ON syslog_analysis(escalation_required);

-- Create GIN index for JSONB analysis data for fast searching
CREATE INDEX IF NOT EXISTS idx_syslog_analysis_mcp_analysis ON syslog_analysis USING GIN (mcp_analysis);

-- Create remediation_executions table to track automated remediation
CREATE TABLE IF NOT EXISTS remediation_executions (
    id SERIAL PRIMARY KEY,
    syslog_id VARCHAR(255) NOT NULL,
    hostname VARCHAR(255) NOT NULL,
    execution_plan JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, running, completed, failed, rolled_back
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    success_rate DECIMAL(5,2) DEFAULT 0.00,
    execution_results JSONB,
    rollback_executed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    FOREIGN KEY (syslog_id) REFERENCES syslog_analysis(syslog_id) ON DELETE CASCADE
);

-- Create indexes for remediation tracking
CREATE INDEX IF NOT EXISTS idx_remediation_executions_syslog_id ON remediation_executions(syslog_id);
CREATE INDEX IF NOT EXISTS idx_remediation_executions_hostname ON remediation_executions(hostname);
CREATE INDEX IF NOT EXISTS idx_remediation_executions_status ON remediation_executions(status);
CREATE INDEX IF NOT EXISTS idx_remediation_executions_started_at ON remediation_executions(started_at);

-- Create syslog_trends table for trend analysis
CREATE TABLE IF NOT EXISTS syslog_trends (
    id SERIAL PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    severity INTEGER NOT NULL,
    facility INTEGER NOT NULL,
    error_pattern VARCHAR(500),
    occurrence_count INTEGER DEFAULT 1,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    trend_period VARCHAR(20) DEFAULT 'daily', -- hourly, daily, weekly
    avg_risk_score DECIMAL(3,1) DEFAULT 0.0,
    escalation_frequency DECIMAL(5,2) DEFAULT 0.00,
    auto_remediation_success_rate DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(hostname, severity, facility, error_pattern, trend_period)
);

-- Create indexes for trend analysis
CREATE INDEX IF NOT EXISTS idx_syslog_trends_hostname_severity ON syslog_trends(hostname, severity);
CREATE INDEX IF NOT EXISTS idx_syslog_trends_last_seen ON syslog_trends(last_seen);
CREATE INDEX IF NOT EXISTS idx_syslog_trends_occurrence_count ON syslog_trends(occurrence_count);

-- Create mcp_server_stats table to track MCP server performance
CREATE TABLE IF NOT EXISTS mcp_server_stats (
    id SERIAL PRIMARY KEY,
    analysis_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_time_ms INTEGER,
    confidence_score DECIMAL(3,2),
    analysis_category VARCHAR(100),
    recommendations_generated INTEGER DEFAULT 0,
    auto_remediation_suggested BOOLEAN DEFAULT FALSE,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for MCP server statistics
CREATE INDEX IF NOT EXISTS idx_mcp_server_stats_timestamp ON mcp_server_stats(analysis_timestamp);
CREATE INDEX IF NOT EXISTS idx_mcp_server_stats_response_time ON mcp_server_stats(response_time_ms);
CREATE INDEX IF NOT EXISTS idx_mcp_server_stats_success ON mcp_server_stats(success);

-- Create views for common queries
CREATE OR REPLACE VIEW high_risk_alerts AS
SELECT 
    syslog_id,
    hostname,
    severity,
    risk_score,
    mcp_analysis->>'category' as category,
    mcp_analysis->'root_cause_analysis'->>'probable_cause' as probable_cause,
    escalation_required,
    auto_remediation_available,
    created_at
FROM syslog_analysis 
WHERE risk_score > 7.0 
ORDER BY risk_score DESC, created_at DESC;

CREATE OR REPLACE VIEW remediation_summary AS
SELECT 
    hostname,
    COUNT(*) as total_remediations,
    AVG(success_rate) as avg_success_rate,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_remediations,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_remediations,
    COUNT(CASE WHEN rollback_executed = true THEN 1 END) as rollbacks_executed,
    MAX(completed_at) as last_remediation
FROM remediation_executions 
GROUP BY hostname
ORDER BY total_remediations DESC;

CREATE OR REPLACE VIEW daily_syslog_summary AS
SELECT 
    DATE(created_at) as analysis_date,
    hostname,
    COUNT(*) as total_messages,
    AVG(risk_score) as avg_risk_score,
    COUNT(CASE WHEN escalation_required = true THEN 1 END) as escalations,
    COUNT(CASE WHEN auto_remediation_available = true THEN 1 END) as auto_remediation_available,
    MAX(severity) as max_severity,
    array_agg(DISTINCT mcp_analysis->>'category') as categories
FROM syslog_analysis 
GROUP BY DATE(created_at), hostname
ORDER BY analysis_date DESC, hostname;

-- Add comments for documentation
COMMENT ON TABLE syslog_analysis IS 'Stores syslog messages with MCP analysis results and recommendations';
COMMENT ON TABLE remediation_executions IS 'Tracks automated remediation execution history and results';
COMMENT ON TABLE syslog_trends IS 'Aggregates syslog patterns and trends for predictive analysis';
COMMENT ON TABLE mcp_server_stats IS 'Monitors MCP server performance and analysis quality';

COMMENT ON VIEW high_risk_alerts IS 'Shows high-risk syslog alerts requiring immediate attention';
COMMENT ON VIEW remediation_summary IS 'Summarizes automated remediation success rates by hostname';
COMMENT ON VIEW daily_syslog_summary IS 'Daily aggregated syslog statistics and trends';

-- Create update trigger for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at columns
CREATE TRIGGER update_syslog_analysis_updated_at BEFORE UPDATE ON syslog_analysis 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_syslog_trends_updated_at BEFORE UPDATE ON syslog_trends 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
