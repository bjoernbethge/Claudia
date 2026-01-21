#!/bin/bash
# Duplicate Code Detection Hook
# Runs after Edit/Write to detect potential code duplication

set -euo pipefail

# Only run for code files
if [[ ! "$CLAUDE_TOOL_INPUT_FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
  exit 0
fi

# Skip if file doesn't exist
if [ ! -f "$CLAUDE_TOOL_INPUT_FILE_PATH" ]; then
  exit 0
fi

file_path="$CLAUDE_TOOL_INPUT_FILE_PATH"
file_content=$(cat "$file_path")

# Extract key patterns from the file
function extract_patterns() {
  local file=$1

  # Extract function/class/component names
  rg "^export (const|function|class|interface|type) (\w+)" -o --no-filename "$file" 2>/dev/null || true
}

# Search for similar patterns in codebase
function find_duplicates() {
  local patterns=$1
  local current_file=$2
  local duplicates=""

  while IFS= read -r pattern; then
    if [ -z "$pattern" ]; then
      continue
    fi

    # Extract just the name
    name=$(echo "$pattern" | awk '{print $NF}')

    # Search for similar names in other files
    matches=$(rg "\\b$name\\b" --files-with-matches --glob '!node_modules' --glob '!dist' --glob '!build' . 2>/dev/null | grep -v "$current_file" || true)

    if [ -n "$matches" ]; then
      duplicates="${duplicates}\n- '$name' also found in: $(echo "$matches" | head -3 | tr '\n' ',' | sed 's/,$//')"
    fi
  done <<< "$patterns"

  echo -e "$duplicates"
}

# Run detection
patterns=$(extract_patterns "$file_path")

if [ -n "$patterns" ]; then
  duplicates=$(find_duplicates "$patterns" "$file_path")

  if [ -n "$duplicates" ] && [ "$duplicates" != "" ]; then
    echo '{"feedback": "⚠️  Potential duplicates detected:"}' >&2
    echo "$duplicates" | grep -v '^$' | head -5 >&2
    echo '{"feedback": "Consider reusing existing code instead of duplicating."}' >&2
  fi
fi

# Non-blocking - always succeed
exit 0
