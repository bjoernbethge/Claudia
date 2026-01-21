---
description: Comprehensive code audit with quality checks, security scanning, and duplicate detection
allowed-tools: Read, Glob, Grep, Bash(npm:*), Bash(npx:*), Bash(git:*)
---

# Code Audit

Perform a comprehensive audit of: ${ARGUMENTS:-the entire codebase}

## Instructions

### 1. **Identify Scope**
   - Determine files to audit based on $ARGUMENTS
   - Default to all `.ts`, `.tsx`, `.js`, `.jsx` files if no directory specified
   - Exclude: `node_modules`, `dist`, `build`, `.next`, coverage reports

### 2. **Automated Quality Checks**

Run these checks in parallel:

```bash
# Linting
npm run lint -- ${ARGUMENTS:-.}

# Type checking
npx tsc --noEmit

# Security scanning
npm audit --audit-level=moderate
npx better-npm-audit audit
```

### 3. **Duplicate Code Detection**

Search for common duplication patterns:
- Similar function signatures
- Repeated GraphQL queries/mutations
- Duplicate React components
- Copy-pasted utility functions

Use grep to find:
```bash
# Find duplicate exports
rg "^export (const|function|class)" --no-heading | sort | uniq -d

# Find similar function names (potential duplicates)
rg "function \w+(Query|Mutation|Hook|Component)" -o --no-heading | sort | uniq -d
```

### 4. **Manual Code Review Checklist**

For each file, verify:

**TypeScript Quality**:
- [ ] No `any` types (use `unknown` instead)
- [ ] Proper type narrowing with type guards
- [ ] Interfaces preferred over types (except unions/intersections)
- [ ] No implicit any from missing types

**Error Handling**:
- [ ] All async operations have error handlers
- [ ] User-facing errors show feedback
- [ ] Errors logged for debugging
- [ ] No silent failures

**UI States** (React components):
- [ ] Loading state handled (only when no data)
- [ ] Error state with user feedback
- [ ] Empty state for lists/collections
- [ ] Success state clearly indicated

**Mutations & Async Operations**:
- [ ] Buttons disabled during operations
- [ ] Loading indicators on buttons
- [ ] `onError` handler with user feedback
- [ ] Optimistic updates where appropriate

**Security**:
- [ ] User input sanitized
- [ ] No SQL/NoSQL injection vectors
- [ ] No XSS vulnerabilities
- [ ] Sensitive data not logged
- [ ] API keys not hardcoded

**Performance**:
- [ ] No unnecessary re-renders
- [ ] Proper memoization (useMemo, useCallback)
- [ ] Large lists virtualized
- [ ] Images optimized and lazy-loaded

### 5. **Report Findings**

Organize by severity:

**🔴 Critical** (must fix immediately):
- Security vulnerabilities
- Runtime errors
- Data loss risks

**🟡 Warning** (should fix soon):
- Type errors
- Missing error handling
- Duplicate code

**🟢 Suggestion** (could improve):
- Code style inconsistencies
- Performance optimizations
- Missing tests

### 6. **Create Action Items**

For each finding:
1. File path with line number
2. Issue description
3. Recommended fix
4. Priority level

Present as a markdown checklist that can be tracked.
