# Task Completion Checklist

## After Modifying Skills/Agents/Commands
1. Validate YAML frontmatter has required fields (name, description)
2. Check description includes trigger phrases
3. Verify file naming follows kebab-case convention
4. Test skill triggers correctly

## After Modifying Hooks
1. Test hook script executes without errors
2. Verify exit codes are correct (0=success, 2=block)
3. Check JSON output format if applicable
4. Test with actual Claude Code events

## After Modifying Docker Config
1. Run `docker compose -f docker-compose.dev.yml config` to validate
2. Test services start correctly
3. Verify health checks pass

## After Modifying MCP Config
1. Validate JSON syntax in .mcp.json
2. Check environment variable references
3. Test MCP server connection

## Before Committing
1. No secrets in committed files
2. .env.example updated if new vars added
3. README.md updated if architecture changed
4. CLAUDE.md updated if new conventions added
