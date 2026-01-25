# Claudia - Project Overview

## Purpose
Claude Code configuration showcase/template project demonstrating best practices for:
- Skills, Agents, Commands, Hooks system
- MCP server integrations
- GitHub Actions automation
- Docker-based development environment

## Tech Stack
- **Configuration**: Markdown + YAML (no application code)
- **Runtime**: Docker Compose for dev services
- **Services**: Ollama (LLM), SearXNG (search), SurrealDB (database)
- **CI/CD**: GitHub Actions with claude-code-action

## Project Structure
```
Claudia/
├── CLAUDE.md              # Project memory for Claude Code
├── .mcp.json              # MCP server configuration
├── docker-compose.dev.yml # Local dev services
├── .claude/
│   ├── settings.json      # Hooks, permissions
│   ├── agents/            # AI agents (code-reviewer, github-workflow)
│   ├── commands/          # Slash commands (/ticket, /pr-review, etc.)
│   ├── hooks/             # skill-eval.js/sh for auto skill detection
│   └── skills/            # Domain knowledge (8 skills)
├── .github/workflows/     # CI/CD pipelines
└── .devcontainer/         # VS Code DevContainer config
```

## Key Concepts
- **Skills**: Domain knowledge in `.claude/skills/{name}/SKILL.md`
- **Agents**: Specialized assistants in `.claude/agents/{name}.md`
- **Commands**: Slash commands in `.claude/commands/{name}.md`
- **Hooks**: Automation scripts triggered by Claude Code events
