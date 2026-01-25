-- DuckDB Initialization Script for Claudia
-- Installs and loads Query.Farm community extensions

-- Core Extensions
INSTALL httpfs;
INSTALL json;
INSTALL parquet;

-- Query.Farm Community Extensions
INSTALL shellfs FROM community;
INSTALL http_client FROM community;
INSTALL datasketches FROM community;
INSTALL chsql FROM community;
INSTALL h3 FROM community;
INSTALL lindel FROM community;
INSTALL vss FROM community;

-- Load Extensions
LOAD httpfs;
LOAD json;
LOAD parquet;
LOAD shellfs;
LOAD http_client;
LOAD datasketches;
LOAD chsql;
LOAD h3;
LOAD lindel;
LOAD vss;

-- Create Claudia Schema
CREATE SCHEMA IF NOT EXISTS claudia;

-- Query Logging Table
CREATE TABLE IF NOT EXISTS claudia.query_log (
    id INTEGER PRIMARY KEY,
    ts TIMESTAMP DEFAULT current_timestamp,
    query TEXT,
    duration_ms DOUBLE,
    rows_returned INTEGER
);

-- Embeddings Cache for Vector Search
CREATE TABLE IF NOT EXISTS claudia.embeddings (
    hash VARCHAR(64) PRIMARY KEY,
    text TEXT,
    embedding FLOAT[],
    model VARCHAR(100),
    created_at TIMESTAMP DEFAULT current_timestamp
);

-- Web Fetch Cache
CREATE TABLE IF NOT EXISTS claudia.http_cache (
    url_hash VARCHAR(64) PRIMARY KEY,
    url TEXT,
    status_code INTEGER,
    headers JSON,
    body TEXT,
    fetched_at TIMESTAMP DEFAULT current_timestamp,
    expires_at TIMESTAMP
);

-- Sequences for auto-increment
CREATE SEQUENCE IF NOT EXISTS claudia.query_log_seq START 1;

-- Helper macro for logging queries
CREATE OR REPLACE MACRO claudia.log_query(q, duration, rows) AS (
    INSERT INTO claudia.query_log (id, query, duration_ms, rows_returned)
    VALUES (nextval('claudia.query_log_seq'), q, duration, rows)
);
