#!/usr/bin/env bash
# Affiche les dernieres lignes du journal applicatif
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 1

NB_LIGNES="${1:-30}"

if [ ! -d logs ]; then
    echo "Aucun dossier logs : lancez d'abord demarrer.sh ou deployer.sh." >&2
    exit 1
fi

# On prend le journal le plus recent (app.log en developpement, deploy.log en production)
LOG_FILE="$(ls -t logs/*.log 2>/dev/null | head -n 1)"
if [ -z "$LOG_FILE" ]; then
    echo "Aucun fichier .log dans logs/ : lancez d'abord demarrer.sh ou deployer.sh." >&2
    exit 1
fi

echo "=== $LOG_FILE (dernieres $NB_LIGNES lignes) ==="
tail -n "$NB_LIGNES" "$LOG_FILE"

echo
echo "=== fichiers de PID suivis ==="
for f in logs/*.pid; do
    [ -e "$f" ] || continue
    if kill -0 "$(cat "$f")" 2>/dev/null; then
        echo "  $f -> PID $(cat "$f") actif"
    else
        echo "  $f -> PID $(cat "$f") inactif"
    fi
done