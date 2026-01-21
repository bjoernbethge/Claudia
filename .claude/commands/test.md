---
description: Run tests with optional filters and arguments
allowed-tools: Bash(npm:*), Bash(npx:*), Read, Glob
---

# Test Runner

Run tests for: ${ARGUMENTS:-all files}

## Instructions

### 1. **Parse Arguments**

Determine test mode from $ARGUMENTS:
- Specific file: `src/components/Button.test.tsx`
- Directory: `src/components/`
- Pattern: `Button`
- Watch mode: `--watch`
- Coverage: `--coverage`
- No arguments: Run all tests

### 2. **Run Tests**

Execute appropriate test command:

```bash
# Specific file or directory
npm test -- ${ARGUMENTS}

# With coverage
npm test -- --coverage ${ARGUMENTS}

# Watch mode
npm test -- --watch ${ARGUMENTS}

# All tests (no arguments)
npm test
```

### 3. **Additional Test Options**

Support common Jest flags:
- `--watch` - Watch for changes
- `--coverage` - Generate coverage report
- `--updateSnapshot` or `-u` - Update snapshots
- `--verbose` - Detailed output
- `--bail` - Stop on first failure
- `--findRelatedTests <file>` - Test related to specific file
- `--onlyChanged` - Only test changed files (git)

### 4. **Coverage Analysis**

If `--coverage` flag is present:
- Show coverage summary
- Identify files below thresholds
- Highlight untested code paths

### 5. **Failure Analysis**

If tests fail:
- Show which tests failed
- Display error messages
- Suggest fixes for common issues:
  - Missing mocks
  - Async timing issues
  - Snapshot mismatches
  - Type errors in tests

### 6. **Related Files**

When testing a specific file, optionally check:
- Is there a corresponding test file?
- If not, offer to create one following TDD patterns
- Check if implementation file exists for test files

## Examples

```bash
/test src/components/Button.test.tsx
/test src/hooks/ --watch
/test --coverage
/test Button --updateSnapshot
```
