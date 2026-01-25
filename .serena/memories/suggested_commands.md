# Suggested Commands

## Docker Services
```bash
# Start all dev services
docker compose -f docker-compose.dev.yml up -d

# Stop services
docker compose -f docker-compose.dev.yml down

# View logs
docker compose -f docker-compose.dev.yml logs -f

# Check service health
docker compose -f docker-compose.dev.yml ps
```

## Service Endpoints
| Service | Port | URL |
|---------|------|-----|
| Ollama | 11434 | http://localhost:11434 |
| SearXNG | 8080 | http://localhost:8080 |
| SurrealDB | 8081 | http://localhost:8081 |

## Windows System Commands
```powershell
# List files
dir
Get-ChildItem

# Find files
Get-ChildItem -Recurse -Filter "*.md"

# Search in files
Select-String -Path "*.md" -Pattern "pattern"

# Git operations
git status
git diff
git log --oneline -10
```

## Claude Code Commands
```bash
# Validate config
/validate-config

# List available skills
/list-skills

# Work on GitHub issue
/ticket <issue-number>

# Create PR summary
/pr-summary

# Run code quality check
/code-quality <directory>
```
