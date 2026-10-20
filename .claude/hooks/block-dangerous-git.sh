#!/bin/bash
# Blocks destructive git commands before Claude Code runs them.
# Based on mattpocock/skills git-guardrails-claude-code (MIT), adapted:
# a plain `git push` is allowed (it is how work gets delivered); force
# pushes and commands that throw away local work are blocked.

INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
else
  COMMAND=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))')
fi

DANGEROUS_PATTERNS=(
  'git push.*(--force([^-]|$)|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[^[:space:]]+)'
  'git reset --hard'
  'git clean -[a-zA-Z]*f'
  'git branch -D'
  'git checkout (--[[:space:]]+)?\.([[:space:]]|$)'
  'git restore (--staged[[:space:]]+)?\.([[:space:]]|$)'
  'git stash (drop|clear)'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if printf '%s' "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches a protected git pattern ('$pattern'). The user has blocked destructive git commands; ask them to run it themselves if it is really needed." >&2
    exit 2
  fi
done

exit 0
