---
name: duckdb-analytics
description: This skill should be used when running SQL queries, analyzing data, fetching web APIs from SQL, reading shell command output as tables, approximate analytics, geospatial H3 indexing, or vector similarity search with DuckDB.
---

# DuckDB Analytics with Query.Farm Extensions

DuckDB is configured as the analytical database layer for Claudia with powerful community extensions from Query.Farm.

## Available MCP Tools

Use the `mcp__duckdb__*` tools:

| Tool | Purpose |
|------|---------|
| `query` | Execute read-only SQL (SELECT) |
| `query_write` | Execute SQL with write access (INSERT/UPDATE/DELETE) |
| `list_tables` | List all tables in database |
| `describe` | Show table structure |
| `shell_read` | Read shell command output as SQL table |
| `http_fetch` | Make HTTP requests from SQL |
| `approx_count` | Approximate distinct count (HyperLogLog) |
| `h3_index` | Convert lat/lng to H3 geospatial index |
| `extensions_status` | Show loaded extensions |

## Extension Patterns

### shellfs - Shell Commands as Tables

Read output from any shell command as a SQL table:

```sql
-- Docker container stats
SELECT * FROM read_csv('docker ps --format "{{.Names}},{{.Status}}" |',
    columns={'name': 'VARCHAR', 'status': 'VARCHAR'});

-- System info
SELECT * FROM read_csv('dir /b |', columns={'filename': 'VARCHAR'});

-- Process list
SELECT * FROM read_csv('tasklist /fo csv /nh |', auto_detect=true);
```

### http_client - HTTP Requests from SQL

Fetch APIs directly in SQL queries:

```sql
-- GET request
SELECT * FROM http_get('http://localhost:11434/api/tags');

-- Parse JSON response
SELECT json_extract_string(body, '$.name') as name
FROM http_get('https://api.example.com/data');

-- SearXNG search
SELECT json_extract_string(r, '$.title') as title,
       json_extract_string(r, '$.url') as url
FROM http_get('http://localhost:8080/search?q=duckdb&format=json')
CROSS JOIN UNNEST(json_extract(body, '$.results')) as t(r);
```

### datasketches - Approximate Analytics

Fast approximate analytics for large datasets:

```sql
-- Approximate distinct count (HyperLogLog)
SELECT datasketch_hll_count(user_id) as approx_users FROM events;

-- Approximate quantiles
SELECT datasketch_quantile(response_time, 0.95) as p95 FROM requests;
```

### h3 - Geospatial Indexing

Uber's H3 hexagonal hierarchical spatial index:

```sql
-- Convert coordinates to H3 cell
SELECT h3_latlng_to_cell(52.52, 13.405, 9) as berlin_h3;

-- Get cell boundary
SELECT h3_cell_to_boundary(h3_index) FROM locations;

-- Find neighbors
SELECT h3_grid_ring(h3_index, 1) FROM locations;
```

### vss - Vector Similarity Search

Vector operations for embeddings:

```sql
-- Create index on embedding column
CREATE INDEX embedding_idx ON claudia.embeddings USING HNSW (embedding);

-- Find similar vectors
SELECT text, array_cosine_similarity(embedding, ?) as similarity
FROM claudia.embeddings
ORDER BY similarity DESC
LIMIT 10;
```

## Schema

The `claudia` schema contains:

- `claudia.query_log` - Query history and performance
- `claudia.embeddings` - Cached embeddings for vector search
- `claudia.http_cache` - HTTP response cache

## Integration Examples

### With Ollama
```sql
-- Get Ollama model list
SELECT json_extract_string(m, '$.name') as model
FROM http_get('http://localhost:11434/api/tags')
CROSS JOIN UNNEST(json_extract(body, '$.models')) as t(m);
```

### With SurrealDB
```sql
-- Query SurrealDB via HTTP
SELECT * FROM http_post('http://localhost:8081/sql',
    headers := {'Accept': 'application/json'},
    body := 'SELECT * FROM users');
```

### System Monitoring Dashboard
```sql
-- Combined system view
SELECT 'containers' as source, name, status FROM read_csv('docker ps --format "{{.Names}},{{.Status}}" |', columns={'name': 'VARCHAR', 'status': 'VARCHAR'})
UNION ALL
SELECT 'volumes' as source, name, driver FROM read_csv('docker volume ls --format "{{.Name}},{{.Driver}}" |', columns={'name': 'VARCHAR', 'driver': 'VARCHAR'});
```

## Best Practices

1. **Use `query` for reads** - The read-only tool prevents accidental modifications
2. **Cache HTTP responses** - Store frequent API calls in `claudia.http_cache`
3. **Use approximate functions** - For large datasets, datasketches is much faster
4. **Index embeddings** - Create HNSW index for vector similarity search
5. **Log important queries** - Use `claudia.log_query()` macro for auditing

## Troubleshooting

If extensions aren't working:
```sql
-- Check extension status
SELECT extension_name, loaded, installed FROM duckdb_extensions();

-- Reinstall extension
INSTALL extension_name FROM community;
LOAD extension_name;
```
