-- DuckDB Examples with Query.Farm Extensions
-- Use these queries to test the DuckDB integration

-- ============================================
-- BASIC QUERIES
-- ============================================

-- Check loaded extensions
SELECT extension_name, loaded, installed
FROM duckdb_extensions()
WHERE loaded = true;

-- List tables in claudia schema
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'claudia';

-- ============================================
-- SHELLFS - Shell Commands as Tables
-- ============================================

-- Docker container list (Linux/Mac)
SELECT * FROM read_csv('docker ps --format "{{.Names}},{{.Status}},{{.Image}}" |',
    columns={'name': 'VARCHAR', 'status': 'VARCHAR', 'image': 'VARCHAR'});

-- Docker container stats
SELECT * FROM read_csv('docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" |',
    columns={'name': 'VARCHAR', 'cpu': 'VARCHAR', 'memory': 'VARCHAR'});

-- Docker volumes
SELECT * FROM read_csv('docker volume ls --format "{{.Name}},{{.Driver}}" |',
    columns={'name': 'VARCHAR', 'driver': 'VARCHAR'});

-- ============================================
-- HTTP_CLIENT - API Requests from SQL
-- ============================================

-- Ollama model list
SELECT * FROM http_get('http://localhost:11434/api/tags');

-- Parse Ollama models
SELECT json_extract_string(m, '$.name') as model_name,
       json_extract_string(m, '$.size') as size
FROM http_get('http://localhost:11434/api/tags')
CROSS JOIN UNNEST(json_extract(body, '$.models')) as t(m);

-- SearXNG search
SELECT json_extract_string(r, '$.title') as title,
       json_extract_string(r, '$.url') as url
FROM http_get('http://localhost:8080/search?q=duckdb+extensions&format=json')
CROSS JOIN UNNEST(json_extract(body, '$.results')) as t(r)
LIMIT 5;

-- ============================================
-- DATASKETCHES - Approximate Analytics
-- ============================================

-- Create sample data for testing
CREATE TABLE IF NOT EXISTS test_events (
    id INTEGER,
    user_id VARCHAR,
    event_type VARCHAR,
    created_at TIMESTAMP DEFAULT current_timestamp
);

-- Insert sample data
INSERT INTO test_events (id, user_id, event_type)
SELECT
    generate_series as id,
    'user_' || (generate_series % 100)::VARCHAR as user_id,
    CASE generate_series % 3
        WHEN 0 THEN 'click'
        WHEN 1 THEN 'view'
        ELSE 'purchase'
    END as event_type
FROM generate_series(1, 10000);

-- Approximate distinct user count
SELECT datasketch_hll_count(user_id) as approx_distinct_users
FROM test_events;

-- Clean up
DROP TABLE IF EXISTS test_events;

-- ============================================
-- H3 - Geospatial Indexing
-- ============================================

-- Convert coordinates to H3 cell (Berlin)
SELECT h3_latlng_to_cell(52.52, 13.405, 9) as berlin_h3;

-- Multiple cities
SELECT city, h3_latlng_to_cell(lat, lng, 9) as h3_index
FROM (VALUES
    ('Berlin', 52.52, 13.405),
    ('New York', 40.7128, -74.0060),
    ('Tokyo', 35.6762, 139.6503),
    ('Sydney', -33.8688, 151.2093)
) as cities(city, lat, lng);

-- ============================================
-- COMBINED EXAMPLES
-- ============================================

-- System monitoring dashboard
SELECT 'container' as type, name as item, status as value
FROM read_csv('docker ps --format "{{.Names}},{{.Status}}" |',
    columns={'name': 'VARCHAR', 'status': 'VARCHAR'})
UNION ALL
SELECT 'volume' as type, name as item, driver as value
FROM read_csv('docker volume ls --format "{{.Name}},{{.Driver}}" |',
    columns={'name': 'VARCHAR', 'driver': 'VARCHAR'});

-- ============================================
-- CLAUDIA SCHEMA OPERATIONS
-- ============================================

-- View recent queries
SELECT id, ts, LEFT(query, 50) as query_preview, duration_ms
FROM claudia.query_log
ORDER BY ts DESC
LIMIT 10;

-- Query performance stats
SELECT
    COUNT(*) as total_queries,
    AVG(duration_ms) as avg_duration_ms,
    MAX(duration_ms) as max_duration_ms,
    SUM(rows_returned) as total_rows
FROM claudia.query_log;

-- ============================================
-- EMBEDDING CACHE
-- ============================================

-- Insert a test embedding (example with dummy vector)
INSERT INTO claudia.embeddings (hash, text, embedding, model)
VALUES (
    md5('test text'),
    'test text',
    [0.1, 0.2, 0.3, 0.4, 0.5]::FLOAT[],
    'test-model'
);

-- Find similar embeddings (cosine similarity)
SELECT text,
       array_cosine_similarity(embedding, [0.1, 0.2, 0.3, 0.4, 0.5]::FLOAT[]) as similarity
FROM claudia.embeddings
ORDER BY similarity DESC
LIMIT 5;

-- Clean up test data
DELETE FROM claudia.embeddings WHERE hash = md5('test text');
