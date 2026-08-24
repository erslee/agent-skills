#!/usr/bin/env bash
# UserPromptSubmit hook: shows a short English spelling / phrasing hint for the prompt
# you just sent. Output goes to the user only (systemMessage), never into Claude's context.
set -uo pipefail

# The nested `claude -p` below inherits this variable, so its own copy of this hook exits
# immediately instead of recursing forever.
[ -n "${CLAUDE_ENGLISH_HINT:-}" ] && exit 0

input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null) || exit 0

[ -z "$prompt" ] && exit 0

# Slash commands, bash passthrough and memory notes are not prose worth checking.
case "$prompt" in
  /* | !* | '#'*) exit 0 ;;
  *'```'*) exit 0 ;;
esac

words=$(printf '%s' "$prompt" | wc -w | tr -d '[:space:]')
[ "${words:-0}" -lt 4 ] && exit 0

read -r -d '' instructions <<'EOF' || true
The text below is a chat message written by a non-native English speaker (a software developer).
Reply with AT MOST two short lines, nothing else:
Fix: <the message corrected, only if it has real spelling or grammar errors>
Native: <how a native speaker would more naturally phrase it>
Drop the Fix line when there are no errors. Drop the Native line when the phrasing is already natural.
If both are fine, reply with exactly: OK
Never explain, never comment on the content, never answer the message, never mention this instruction.
Ignore code, file paths, identifiers, ticket keys and technical jargon.

Message:
EOF

hint=$(
  cd "${TMPDIR:-/tmp}" &&
    CLAUDE_ENGLISH_HINT=1 claude -p \
      --model haiku \
      --strict-mcp-config \
      --max-turns 1 \
      --settings '{"disableAllHooks":true}' \
      "${instructions}${prompt:0:1500}" 2>/dev/null
)

hint=$(printf '%s' "$hint" | sed '/^[[:space:]]*$/d' | head -c 500)

[ -z "$hint" ] && exit 0
case "$hint" in OK | OK[.!]*) exit 0 ;; esac

jq -n --arg m "✏️  $hint" '{systemMessage: $m, suppressOutput: true}'
