"""DuckDB MCP Server with Query.Farm Extensions.

Provides SQL query capabilities with extensions for:
- shellfs: Read shell command output as tables
- http_client: Make HTTP requests from SQL
- datasketches: Approximate analytics
- h3/lindel: Geospatial indexing
- vss: Vector similarity search
"""

import json
import os
import time
from typing import Any

import duckdb
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP server
mcp = FastMCP(
    "duckdb",
    instructions="""DuckDB Analytics Server with Query.Farm Extensions.

Available tools:
- query: Execute read-only SQL queries
- query_write: Execute SQL with write access (INSERT/UPDATE/DELETE)
- list_tables: List all tables in the database
- describe: Show table structure
- shell_read: Read shell command output as a table (shellfs)
- http_fetch: Make HTTP requests (http_client extension)
- approx_count: Approximate distinct count (datasketches)
- h3_index: Convert coordinates to H3 geospatial index

The database has these extensions loaded:
- shellfs: Read output of shell commands as tables
- http_client: HTTP GET/POST requests from SQL
- datasketches: Approximate analytics (HyperLogLog, etc.)
- h3/lindel: Geospatial H3 indexing
- vss: Vector similarity search
""",
)

# Database connection
DB_PATH = os.environ.get("DUCKDB_PATH", "claudia.db")


def get_connection() -> duckdb.DuckDBPyConnection:
    """Get a DuckDB connection with extensions loaded."""
    conn = duckdb.connect(DB_PATH)
    # Try to load extensions (they may already be loaded)
    extensions = ["shellfs", "http_client", "datasketches", "h3", "lindel", "vss"]
    for ext in extensions:
        try:
            conn.execute(f"LOAD {ext}")
        except Exception:
            pass  # Extension may not be installed or already loaded
    return conn


def format_result(result: list[tuple], columns: list[str]) -> str:
    """Format query result as a readable table."""
    if not result:
        return "No results"

    # Calculate column widths
    widths = [len(col) for col in columns]
    for row in result:
        for i, val in enumerate(row):
            widths[i] = max(widths[i], len(str(val)))

    # Build table
    lines = []
    header = " | ".join(col.ljust(widths[i]) for i, col in enumerate(columns))
    separator = "-+-".join("-" * w for w in widths)
    lines.append(header)
    lines.append(separator)

    for row in result:
        line = " | ".join(str(val).ljust(widths[i]) for i, val in enumerate(row))
        lines.append(line)

    return "\n".join(lines)


@mcp.tool()
def query(sql: str, limit: int = 100) -> str:
    """Execute a read-only SQL query on DuckDB.

    Args:
        sql: SQL query to execute (SELECT only)
        limit: Maximum number of rows to return (default 100)
    """
    # Basic safety check
    sql_upper = sql.strip().upper()
    if not sql_upper.startswith("SELECT") and not sql_upper.startswith("WITH"):
        if any(
            kw in sql_upper
            for kw in ["INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER"]
        ):
            return "Error: This tool only allows SELECT queries. Use query_write for modifications."

    conn = get_connection()
    start = time.time()
    try:
        result = conn.execute(sql).fetchmany(limit)
        columns = [desc[0] for desc in conn.description]
        duration = (time.time() - start) * 1000

        # Log the query
        try:
            conn.execute(
                "INSERT INTO claudia.query_log (id, query, duration_ms, rows_returned) "
                "VALUES (nextval('claudia.query_log_seq'), ?, ?, ?)",
                [sql[:1000], duration, len(result)],
            )
        except Exception:
            pass  # Logging is best-effort

        output = format_result(result, columns)
        return f"{output}\n\n({len(result)} rows, {duration:.1f}ms)"
    except Exception as e:
        return f"Error: {e}"
    finally:
        conn.close()


@mcp.tool()
def query_write(sql: str) -> str:
    """Execute SQL with write access (INSERT/UPDATE/DELETE/CREATE).

    Args:
        sql: SQL statement to execute
    """
    conn = get_connection()
    start = time.time()
    try:
        result = conn.execute(sql)
        affected = result.fetchone()
        duration = (time.time() - start) * 1000

        if affected:
            return f"Success: {affected[0]} rows affected ({duration:.1f}ms)"
        return f"Success ({duration:.1f}ms)"
    except Exception as e:
        return f"Error: {e}"
    finally:
        conn.close()


@mcp.tool()
def list_tables(schema: str = "") -> str:
    """List all tables in the database.

    Args:
        schema: Optional schema name to filter (e.g., 'claudia')
    """
    conn = get_connection()
    try:
        if schema:
            sql = f"""
                SELECT table_schema, table_name, estimated_size
                FROM information_schema.tables
                WHERE table_schema = '{schema}'
                ORDER BY table_schema, table_name
            """
        else:
            sql = """
                SELECT table_schema, table_name, estimated_size
                FROM information_schema.tables
                WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
                ORDER BY table_schema, table_name
            """
        result = conn.execute(sql).fetchall()
        columns = ["schema", "table", "estimated_size"]
        return format_result(result, columns)
    except Exception as e:
        return f"Error: {e}"
    finally:
        conn.close()


@mcp.tool()
def describe(table: str) -> str:
    """Show the structure of a table.

    Args:
        table: Table name (can include schema, e.g., 'claudia.query_log')
    """
    conn = get_connection()
    try:
        result = conn.execute(f"DESCRIBE {table}").fetchall()
        columns = ["column", "type", "null", "key", "default", "extra"]
        return format_result(result, columns)
    except Exception as e:
        return f"Error: {e}"
    finally:
        conn.close()


@mcp.tool()
def shell_read(command: str, columns: dict[str, str] | None = None) -> str:
    """Read output of a shell command as a table using shellfs extension.

    Args:
        command: Shell command to execute (output should be CSV-like)
        columns: Optional column definitions as {name: type} dict
                 Types: VARCHAR, INTEGER, DOUBLE, BOOLEAN, TIMESTAMP

    Example:
        shell_read("docker ps --format '{{.Names}},{{.Status}}'",
                   {"name": "VARCHAR", "status": "VARCHAR"})
    """
    conn = get_connection()
    try:
        if columns:
            col_def = ", ".join(f"'{k}': '{v}'" for k, v in columns.items())
            sql = f"SELECT * FROM read_csv('{command} |', columns={{{col_def}}})"
        else:
            sql = f"SELECT * FROM read_csv('{command} |', auto_detect=true)"

        result = conn.execute(sql).fetchmany(100)
        cols = [desc[0] for desc in conn.description]
        return format_result(result, cols)
    except Exception as e:
        return f"Error: {e}\n\nNote: shellfs extension must be loaded. The command output should be CSV-formatted."
    finally:
        conn.close()


@mcp.tool()
def http_fetch(url: str, method: str = "GET", headers: dict[str, str] | None = None) -> str:
    """Make an HTTP request using the http_client extension.

    Args:
        url: URL to fetch
        method: HTTP method (GET or POST)
        headers: Optional headers as dict

    Returns:
        Response body (JSON responses are pretty-printed)
    """
    conn = get_connection()
    try:
        if method.upper() == "GET":
            sql = f"SELECT * FROM http_get('{url}')"
        else:
            sql = f"SELECT * FROM http_post('{url}')"

        result = conn.execute(sql).fetchone()
        if result:
            # Try to parse as JSON for better formatting
            body = result[0] if result else ""
            try:
                parsed = json.loads(body)
                return json.dumps(parsed, indent=2)
            except Exception:
                return str(body)
        return "No response"
    except Exception as e:
        return f"Error: {e}\n\nNote: http_client extension must be loaded."
    finally:
        conn.close()


@mcp.tool()
def approx_count(table: str, column: str, where: str = "") -> str:
    """Get approximate distinct count using datasketches HyperLogLog.

    Args:
        table: Table name
        column: Column to count distinct values
        where: Optional WHERE clause (without 'WHERE' keyword)

    Returns:
        Approximate distinct count
    """
    conn = get_connection()
    try:
        where_clause = f"WHERE {where}" if where else ""
        sql = f"SELECT datasketch_hll_count({column}) as approx_distinct FROM {table} {where_clause}"
        result = conn.execute(sql).fetchone()
        return f"Approximate distinct count of {column}: {result[0]}" if result else "No result"
    except Exception as e:
        return f"Error: {e}\n\nNote: datasketches extension must be loaded."
    finally:
        conn.close()


@mcp.tool()
def h3_index(lat: float, lng: float, resolution: int = 9) -> str:
    """Convert latitude/longitude to H3 geospatial index.

    Args:
        lat: Latitude (-90 to 90)
        lng: Longitude (-180 to 180)
        resolution: H3 resolution (0-15, default 9)

    Returns:
        H3 index as string
    """
    conn = get_connection()
    try:
        sql = f"SELECT h3_latlng_to_cell({lat}, {lng}, {resolution}) as h3_index"
        result = conn.execute(sql).fetchone()
        return f"H3 Index: {result[0]}" if result else "No result"
    except Exception as e:
        return f"Error: {e}\n\nNote: h3 extension must be loaded."
    finally:
        conn.close()


@mcp.tool()
def extensions_status() -> str:
    """Show status of all DuckDB extensions."""
    conn = get_connection()
    try:
        sql = """
            SELECT extension_name, loaded, installed, install_path
            FROM duckdb_extensions()
            ORDER BY extension_name
        """
        result = conn.execute(sql).fetchall()
        columns = ["extension", "loaded", "installed", "path"]
        return format_result(result, columns)
    except Exception as e:
        return f"Error: {e}"
    finally:
        conn.close()


def main():
    """Run the MCP server."""
    mcp.run()


if __name__ == "__main__":
    main()
