#!/bin/bash
# Auto-install dependencies when package.json changes
set -euo pipefail

if [[ "$CLAUDE_TOOL_INPUT_FILE_PATH" =~ package\.json$ ]]; then
  echo '{"feedback": "Installing dependencies..."}' >&2
  npm install >/dev/null 2>&1 && echo '{"feedback": "Dependencies installed.", "suppressOutput": true}' || {
    echo '{"feedback": "Failed to install dependencies."}' >&2
    exit 1
  }
fi
