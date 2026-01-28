# GitHub Copilot Instructions for Claudia

## What This Repository Is
**Claudia** is a Claude Code configuration showcase—a template demonstrating best practices for AI-assisted development. It is **NOT** a traditional application but a reference implementation showing how to configure Claude Code with skills, agents, hooks, MCP servers, and CI/CD workflows.

**Critical Facts:**
- **Type**: Documentation/Configuration repository (not production code)
- **Languages**: Config files (JSON, YAML, MD), Python (MCP server), JS (hooks), SQL
- **NO Build Process**: No package.json, no npm install, no npm build, no tests to run
- **Runtime**: Node.js 20+, Python 3.11+, Docker Compose
- **Size**: ~50 files (mostly docs and config)

**⚠️ CI workflow references `npm` commands but they are placeholders for template users. CI jobs WILL fail—this is expected.**

## Repository Structure
```
Claudia/
├── .github/workflows/     # 9 CI/CD workflows (ci, semgrep, codeql, PR reviews, scheduled maintenance)
├── .claude/              # Core: settings.json (hooks), agents/, commands/, skills/ (9 skills), hooks/ (7 scripts)
├── src/mcp/duckdb_server/ # Python MCP server (pyproject.toml, server.py)
├── duckdb/               # SQL init scripts, examples
├── .devcontainer/        # VS Code DevContainer config
├── .mcp.json             # MCP servers: memory, playwright, duckdb
├── docker-compose.dev.yml # Services: Ollama:11434, SearXNG:8080, SurrealDB:8081, DuckDB:9999
├── CLAUDE.md             # Claude Code project memory
├── README.md             # Main docs (32KB)
└── .env.example          # Environment variables template
```

**Key Directories:**
- `.claude/skills/`: 9 skills (testing-patterns, systematic-debugging, react-ui-patterns, graphql-schema, core-components, formik-patterns, duckdb-analytics, performance-optimization, security-best-practices)
- `.claude/agents/`: Custom agents (code-reviewer.md, github-workflow.md)
- `.claude/commands/`: Slash commands (/audit, /ticket, /pr-review, /test, /code-quality, /docs-sync, /onboard, /validate-config)
- `.claude/hooks/`: 7 automation scripts (format-check, npm-install, test-runner, type-check, duplicate-detector, main-branch-protection, skill-eval)

## Environment & Services

### Start Docker Services
```bash
docker compose -f docker-compose.dev.yml up -d
```
**Services:** Ollama (localhost:11434), SearXNG (localhost:8080), SurrealDB (localhost:8081), DuckDB (localhost:9999)

**Verify:**
```bash
docker compose -f docker-compose.dev.yml ps  # Check all "Up"
curl http://localhost:11434/api/tags  # Ollama
curl http://localhost:8080            # SearXNG
curl http://localhost:8081/health     # SurrealDB
```

**Known Issue:** docker-compose.dev.yml has YAML syntax error at line 55 (multi-line Python command). May need to use `docker-compose` (v1) or fix formatting.

### Python MCP Server Setup
```bash
cd src/mcp/duckdb_server
curl -LsSf https://astral.sh/uv/install.sh | sh  # Install uv (or use pip)
uv sync
uv run python -m duckdb_server.server  # Test
```

**MCP Tools Available:** `mcp__duckdb__query`, `query_write`, `list_tables`, `describe`, `shell_read`, `http_fetch`, `approx_count`, `h3_index`

### Environment Variables
Copy `.env.example` to `.env`:
- **GITHUB_TOKEN** (required for GitHub MCP): repo, workflow, read:org scopes
- **DUCKDB_PATH**: Default `data/claudia.db`
- **Optional**: SERENA_API_KEY, CONTEXT7_API_KEY, PLAYWRIGHT_HEADLESS, ANTHROPIC_API_KEY (CI), CODECOV_TOKEN, SEMGREP_APP_TOKEN

## Validation (NOT Traditional Testing)

### DO NOT Run
- ❌ `npm install` (no package.json)
- ❌ `npm test` (no tests exist)
- ❌ `npm run build` (nothing to build)
- ❌ `npm run lint` (no linters configured)

### DO Validate
```bash
# 1. Docker services
docker compose -f docker-compose.dev.yml ps

# 2. Hooks
echo '{"prompt": "test"}' | bash .claude/hooks/skill-eval.sh
ls -la .claude/hooks/*.sh  # Check executable

# 3. JSON config
cat .claude/settings.json | python3 -m json.tool > /dev/null
cat .mcp.json | python3 -m json.tool > /dev/null

# 4. DuckDB
docker exec claudia-duckdb python3 -c "import duckdb; print(duckdb.connect('/data/claudia.db').execute('SELECT 1').fetchone())"
```

## CI/CD Workflows

**On PR (code changes only):**
1. `ci.yml` - Placeholder lint/test/build (WILL FAIL—expected for this template)
2. `semgrep.yml` - SAST security scanning
3. `codeql.yml` - Semantic analysis
4. `pr-claude-code-review.yml` - Claude Opus 4.5 review using `.claude/agents/code-reviewer.md`

**Scheduled:**
- Weekly (Mon 9 AM UTC): Auto-improvement
- Monthly (1st): Docs sync
- Biweekly: Dependency audit
- Weekly (Mon 8 AM UTC): Code quality review

## Making Changes

### Typical Workflow
```bash
# Branch naming: {initials}/{description}
git checkout -b jd/update-config

# Edit files (no build/test needed)
# - Docs: README.md, CLAUDE.md, .claude/SETUP.md
# - Config: .claude/settings.json, .mcp.json
# - Workflows: .github/workflows/*.yml
# - Docker: docker-compose.dev.yml
# - MCP: src/mcp/duckdb_server/

# Validate
cat changed.json | python3 -m json.tool  # JSON files
docker compose -f docker-compose.dev.yml config  # Docker (has known error)

# Commit (Conventional Commits)
git commit -m "feat: add new skill"

# Push and PR
git push -u origin jd/update-config
gh pr create --title "feat: add new skill" --body "Closes #123"
```

### Validation by File Type
- **Documentation**: No validation needed
- **JSON config**: `python3 -m json.tool`
- **YAML workflows**: GitHub validates on push
- **Docker compose**: `docker compose config` (note: current file has error)
- **Python MCP**: `cd src/mcp/duckdb_server && uv run python -m duckdb_server.server`
- **Hooks**: Test manually with test input

## Claude Code Integration

**Hooks** (.claude/settings.json):
- Pre-Tool: Main branch protection
- Post-Tool: Prettier format, npm install (N/A), test runner (N/A), type check (N/A), duplicate detection
- User Prompt: Skill evaluation (suggests relevant skills)

**Skills** (9 in .claude/skills/): Activated via `/list-skills` or auto-suggested by skill-eval hook

**Commands** (/command-name): audit, test, code-quality, docs-sync, pr-review, pr-summary, ticket, list-skills, onboard, validate-config

**Agents** (.claude/agents/): code-reviewer (comprehensive checklist), github-workflow

## Common Pitfalls

1. **CI references npm but no package.json**: This is a template. CI failures are expected for this repo.
2. **docker-compose.dev.yml syntax error (line 55)**: Use `docker-compose` (v1) or fix multi-line command formatting.
3. **MCP requires `uv`**: Install via curl or use `pip install duckdb mcp pydantic`.
4. **Hooks need $CLAUDE_PROJECT_DIR**: Set manually if testing outside Claude Code: `export CLAUDE_PROJECT_DIR=/path/to/Claudia`.
5. **Services take 30-60s to start**: Wait for health checks before testing.

## Key Files to Review

**Before any changes:**
- `README.md` (32KB complete overview)
- `.claude/SETUP.md` (step-by-step setup)
- `CLAUDE.md` (project memory)

**Core config:**
- `.claude/settings.json` (hooks)
- `.mcp.json` (MCP servers)
- `.github/workflows/ci.yml` (CI template)

**For extensions:**
- `.claude/skills/README.md` (create skills)
- `.claude/hooks/skill-rules.json` (pattern matching)
- `src/mcp/duckdb_server/server.py` (MCP example)

## Final Notes

**This is a REFERENCE TEMPLATE.** When adapting for your project, add: package.json, tsconfig.json, ESLint, Prettier, tests, and update CI workflows. The current CI workflow is a placeholder showing desired structure.

**Trust these instructions.** Search only if details are missing or incorrect. Focus on configuration/documentation changes, not application code.
