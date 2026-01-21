#!/bin/bash
# Auto-run tests when test files change
set -euo pipefail

if [[ "$CLAUDE_TOOL_INPUT_FILE_PATH" =~ \.test\.(js|jsx|ts|tsx)$ ]]; then
  echo '{"feedback": "Running tests..."}' >&2
  npm test -- --findRelatedTests "${CLAUDE_TOOL_INPUT_FILE_PATH}" --passWithNoTests 2>&1 | tail -30
  exit_code=${PIPESTATUS[0]}
  if [ $exit_code -eq 0 ]; then
    echo '{"feedback": "Tests passed."}'
  else
    echo '{"feedback": "Tests failed. See output above."}' >&2
  fi
fi
