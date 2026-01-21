#!/bin/bash
# Prevent editing on main branch
set -euo pipefail

current_branch=$(git branch --show-current)
if [ "$current_branch" = "main" ]; then
  echo '{"block": true, "message": "Cannot edit files on main branch. Create a feature branch first."}' >&2
  exit 2
fi
