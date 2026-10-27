#!/usr/bin/env bash
cmd=$(jq -r '.tool_input.command // empty')

# Ne vérifie que les commits avec message en ligne (git commit -m, -am, etc.)
if echo "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]+[^;&|]*)?[[:space:]]-[a-zA-Z]*m([[:space:]]|=|"|'"'"'|$)'; then
  if ! echo "$cmd" | grep -qE '#[0-9]+'; then
    echo "Commit refusé : le message doit contenir un numéro d'issue (ex. #42). Demande-le à l'utilisateur." >&2
    exit 2
  fi
fi
exit 0
