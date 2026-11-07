#!/usr/bin/env bash
# Construit le JAR puis le lance comme un vrai artefact de production
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 1
mkdir -p logs

PORT=8110
PID_FILE="logs/deploy.pid"
LOG_FILE="logs/deploy.log"
ARTIFACT_DIR="target"

if command -v mvn >/dev/null 2>&1; then
    MVN="mvn"
elif command -v mvn.cmd >/dev/null 2>&1; then
    MVN="mvn.cmd"
else
    echo "Maven est introuvable dans le PATH." >&2
    exit 1
fi

echo "1/3 Nettoyage et construction du livrable ..."
if ! "$MVN" -B -q clean package -DskipTests; then
    echo "La construction a echoue. Deploiement annule." >&2
    exit 1
fi

JAR="$(find "$ARTIFACT_DIR" -maxdepth 1 -name '*.jar' ! -name '*sources*' ! -name '*javadoc*' | head -n 1)"
if [ -z "$JAR" ]; then
    echo "Aucun JAR trouve dans $ARTIFACT_DIR." >&2
    exit 1
fi
echo "    Livrable : $JAR ($(du -h "$JAR" | cut -f1))"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "2/3 Arret de l'instance precedente (PID $(cat "$PID_FILE")) ..."
    kill -9 "$(cat "$PID_FILE")" 2>/dev/null
    sleep 2
fi

echo "2/3 Lancement du JAR ..."
nohup java -jar "$JAR" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "3/3 Attente de la disponibilite sur le port $PORT ..."
for _ in $(seq 1 60); do
    if curl -s -o /dev/null "http://localhost:$PORT/actuator/health"; then
        echo "Deploiement termine : http://localhost:$PORT (PID $(cat "$PID_FILE"))"
        exit 0
    fi
    sleep 1
done

echo "Le deploiement n'a pas abouti. Consultez $LOG_FILE." >&2
exit 1
