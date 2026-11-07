#!/usr/bin/env bash
# Verifie l'etat de sante expose par Spring Boot Actuator
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 1

PORT=8110
URL="http://localhost:$PORT/actuator/health"

REPONSE="$(curl -s -m 5 "$URL")"
if [ -z "$REPONSE" ]; then
    echo "Aucune reponse sur $URL : l'application est arretee." >&2
    exit 1
fi

echo "URL    : $URL"
echo "Reponse: $REPONSE"

if echo "$REPONSE" | grep -q '"status":"UP"'; then
    echo "Verdict: le service est operationnel."
    exit 0
fi

echo "Verdict: le service est degrade." >&2
exit 2
