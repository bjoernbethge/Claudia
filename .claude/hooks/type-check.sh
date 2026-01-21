#!/bin/bash
# Type-check TypeScript files
set -euo pipefail

if [[ "$CLAUDE_TOOL_INPUT_FILE_PATH" =~ \.(ts|tsx)$ ]]; then
  echo '{"feedback": "Checking TypeScript types..."}' >&2
  output=$(npx tsc --noEmit 2>&1)
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo '{"feedback": "No TypeScript errors.", "suppressOutput": true}'
  else
    errors=$(echo "$output" | grep -A 2 "error TS" | head -30)
    if [ -n "$errors" ]; then
      echo '{"feedback": "TypeScript found type errors:"}' >&2
      echo "$errors" >&2
    fi
  fi
  # Non-blocking
  exit 0
fi
