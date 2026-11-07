#!/usr/bin/env bash
# Demarre l'application en arriere-plan et journalise sa sortie dans logs/app.log
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 1
mkdir -p logs

PORT=8110
PID_FILE="logs/app.pid"
LOG_FILE="logs/app.log"

# Maven n'a pas le meme nom sur Linux (mvn) et sur Windows/Git Bash (mvn.cmd)
if command -v mvn >/dev/null 2>&1; then
    MVN="mvn"
elif command -v mvn.cmd >/dev/null 2>&1; then
    MVN="mvn.cmd"
else
    echo "Maven est introuvable dans le PATH." >&2
    exit 1
fi

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "L'application tourne deja (PID $(cat "$PID_FILE"))."
    exit 0
fi

echo "Demarrage de pilotage-deploiement sur le port $PORT ..."
nohup "$MVN" spring-boot:run > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

# On attend que le port reponde, au maximum 90 secondes
for _ in $(seq 1 90); do
    if curl -s -o /dev/null "http://localhost:$PORT/actuator/health"; then
        echo "Application disponible : http://localhost:$PORT"
        echo "PID enregistre dans $PID_FILE (valeur $(cat "$PID_FILE"))."
        echo "Journal : $LOG_FILE"
        exit 0
    fi
    sleep 1
done

echo "Le port $PORT ne repond pas. Consultez $LOG_FILE." >&2
exit 1
