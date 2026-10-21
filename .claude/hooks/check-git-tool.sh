#!/bin/sh
# Hook PreToolUse sur l'outil MCP mcp__git__git_commit : bloque un message sans numero d'issue.
# Claude Code envoie un JSON sur stdin : { "tool_input": { "repo_path": "...", "message": "..." }, ... }
# exit 2 = appel bloque, le message stderr est renvoye a l'agent.
raw=$(cat)

if command -v jq >/dev/null 2>&1; then
  msg=$(printf '%s' "$raw" | jq -r '.tool_input.message // empty')
else
  msg=$raw   # sans jq : on cherche directement dans le JSON brut
fi

printf '%s' "$msg" | grep -Eq '#[0-9]+' && exit 0

echo "Commit bloque : le message doit contenir un numero d'issue (ex: #123). Demande le numero a l'utilisateur." >&2
exit 2
