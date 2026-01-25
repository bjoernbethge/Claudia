# Style and Conventions

## File Naming
- Skills: `.claude/skills/{kebab-case}/SKILL.md`
- Agents: `.claude/agents/{kebab-case}.md`
- Commands: `.claude/commands/{kebab-case}.md`

## YAML Frontmatter (required)
```yaml
---
name: skill-name
description: When to use this skill. Include trigger keywords.
---
```

## Markdown Content
- Use imperative form ("Create", "Run", "Configure")
- Keep descriptions under 1024 chars
- Include code examples with language tags
- Use tables for structured data

## Skill Descriptions
- Use third person: "This skill should be used when..."
- Include specific trigger phrases users would say
- List concrete scenarios

## Hook Scripts
- Exit code 0 = success
- Exit code 2 = blocking error
- Return JSON for complex responses:
  ```json
  {"block": true, "message": "Reason"}
  ```

## MCP Configuration
- Use `${VAR}` for environment variables
- Use `${VAR:-default}` for defaults
- Never commit secrets to .mcp.json
