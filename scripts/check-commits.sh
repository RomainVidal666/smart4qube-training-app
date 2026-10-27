#!/bin/bash
# Verifie que chaque commit de BASE..HEAD contient un numero d'issue (#123).
# Usage : bash scripts/check-commits.sh <base> [head]     (utilisable aussi en local)
base="$1"
head="${2:-HEAD}"
[ -z "$base" ] && { echo "Usage: $0 <base> [head]" >&2; exit 2; }

bad=0
for sha in $(git rev-list --no-merges "$base..$head"); do
  msg=$(git log -1 --format=%B "$sha")
  case "$msg" in Revert\ *) continue ;; esac
  if ! printf '%s\n' "$msg" | grep -Eq '#[0-9]+'; then
    echo "KO  $(git log -1 --format='%h %s' "$sha")  -> pas de numero d'issue"
    bad=1
  fi
done

if [ "$bad" -ne 0 ]; then
  echo "Echec : certains commits n'ont pas de numero d'issue (ex: #52)." >&2
  exit 1
fi
echo "OK : tous les commits referencent une issue."
