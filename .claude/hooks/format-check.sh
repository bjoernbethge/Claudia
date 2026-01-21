#!/bin/bash
# Auto-format JS/TS files with Prettier
set -euo pipefail

if [[ "$CLAUDE_TOOL_INPUT_FILE_PATH" =~ \.(js|jsx|ts|tsx)$ ]]; then
  file_path="${CLAUDE_TOOL_INPUT_FILE_PATH}"
  # Use prettier (swap for biome if preferred)
  npx prettier --write "$file_path" 2>&1
  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo '{"feedback": "Formatting failed. Check file for syntax errors."}' >&2
    exit 1
  else
    echo '{"feedback": "Formatting applied.", "suppressOutput": true}'
  fi
fi
