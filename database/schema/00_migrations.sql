-- Migration Management Schema
-- Tracks database schema versions and migrations

CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time INTEGER, -- milliseconds
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT
);

-- Comments
COMMENT ON TABLE schema_migrations IS 'Tracks executed database migrations';
COMMENT ON COLUMN schema_migrations.version IS 'Migration version identifier (e.g., 20251118_001)';
COMMENT ON COLUMN schema_migrations.execution_time IS 'Migration execution time in milliseconds';
