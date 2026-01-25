# DuckDB Integration for Claudia

DuckDB configured as the analytical database layer with Query.Farm community extensions.

## Quick Start

### 1. Start Docker Service

```bash
docker compose -f docker-compose.dev.yml up duckdb -d
```

### 2. Verify Service

```bash
# Check container is running
docker ps | grep claudia-duckdb

# Execute a test query
docker exec claudia-duckdb python -c "import duckdb; print(duckdb.connect('/data/claudia.db').execute('SELECT 1 as test').fetchone())"
```

### 3. Check Extensions

```bash
docker exec claudia-duckdb python -c "
import duckdb
conn = duckdb.connect('/data/claudia.db')
result = conn.execute('SELECT extension_name, loaded FROM duckdb_extensions() WHERE loaded = true').fetchall()
print('Loaded extensions:', [r[0] for r in result])
"
```

## MCP Server Setup

### Install Dependencies

```bash
cd src/mcp/duckdb_server
uv sync
```

### Test MCP Server

```bash
uv run python -m duckdb_server.server
```

The server will start in stdio mode. In Claude Code, the MCP tools will be available as:
- `mcp__duckdb__query`
- `mcp__duckdb__query_write`
- `mcp__duckdb__list_tables`
- `mcp__duckdb__describe`
- `mcp__duckdb__shell_read`
- `mcp__duckdb__http_fetch`
- `mcp__duckdb__approx_count`
- `mcp__duckdb__h3_index`
- `mcp__duckdb__extensions_status`

## Extensions

| Extension | Purpose | Source |
|-----------|---------|--------|
| shellfs | Read shell command output as tables | Query.Farm |
| http_client | HTTP requests from SQL | Query.Farm |
| datasketches | Approximate analytics (HLL) | Query.Farm |
| chsql | ClickHouse SQL compatibility | Query.Farm |
| h3 | Uber H3 geospatial indexing | Query.Farm |
| lindel | Linear algebraic operations | Query.Farm |
| vss | Vector similarity search | Query.Farm |
| httpfs | Remote file access | Core |
| json | JSON operations | Core |
| parquet | Parquet file support | Core |

## Files

```
duckdb/
├── init.sql      # Database initialization script
├── examples.sql  # Example queries for testing
└── README.md     # This file

src/mcp/duckdb_server/
├── pyproject.toml
└── duckdb_server/
    ├── __init__.py
    └── server.py   # MCP server implementation

data/
└── claudia.db    # DuckDB database file (created on first run)
```

## Database Schema

### claudia.query_log
Logs executed queries for auditing and performance analysis.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| ts | TIMESTAMP | Query timestamp |
| query | TEXT | SQL query text |
| duration_ms | DOUBLE | Execution time in ms |
| rows_returned | INTEGER | Number of rows returned |

### claudia.embeddings
Cache for vector embeddings.

| Column | Type | Description |
|--------|------|-------------|
| hash | VARCHAR(64) | MD5 hash of text (PK) |
| text | TEXT | Original text |
| embedding | FLOAT[] | Vector embedding |
| model | VARCHAR(100) | Model used |
| created_at | TIMESTAMP | Creation timestamp |

### claudia.http_cache
Cache for HTTP responses.

| Column | Type | Description |
|--------|------|-------------|
| url_hash | VARCHAR(64) | MD5 hash of URL (PK) |
| url | TEXT | Original URL |
| status_code | INTEGER | HTTP status code |
| headers | JSON | Response headers |
| body | TEXT | Response body |
| fetched_at | TIMESTAMP | Fetch timestamp |
| expires_at | TIMESTAMP | Cache expiry |

## Troubleshooting

### Extension not loading
```sql
INSTALL extension_name FROM community;
LOAD extension_name;
```

### Permission denied on shell commands
Ensure Docker has access to execute the commands. The shellfs extension runs commands inside the container.

### HTTP requests failing
Check that the target services (Ollama, SearXNG, etc.) are running and accessible from the DuckDB container.
