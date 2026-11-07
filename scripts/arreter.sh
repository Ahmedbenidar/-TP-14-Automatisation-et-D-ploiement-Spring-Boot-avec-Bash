#!/usr/bin/env bash
# Arrete l'instance lancee par demarrer.sh (developpement) ou deployer.sh (production)
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 1

PORT=8110
PIDS=""

# 1) On privilegie les fichiers de PID ecrits par les scripts de lancement
for f in logs/app.pid logs/deploy.pid; do
    if [ -f "$f" ]; then
        CANDIDAT="$(cat "$f")"
        if [ -n "$CANDIDAT" ] && kill -0 "$CANDIDAT" 2>/dev/null; then
            echo "Instance trouvee via $f (PID $CANDIDAT)."
            PIDS="$PIDS $CANDIDAT"
        fi
        rm -f "$f"
    fi
done

# 2) Le plugin spring-boot:run lance un processus Java enfant : on complete
#    la liste avec tout processus qui ecoute reellement sur le port applicatif
for f in $(netstat -ano 2>/dev/null | grep -i "LISTENING" | grep ":$PORT " | awk '{print $NF}' | sort -u); do
    case " $PIDS " in
        *" $f "*) ;;
        *) echo "Port $PORT tenu par le PID $f (netstat)."; PIDS="$PIDS $f" ;;
    esac
done

# 3) Dernier repli : on cherche le processus Java qui execute notre livrable
if [ -z "$PIDS" ]; then
    for f in $(ps aux | grep -E 'spring-boot:run|pilotage-deploiement' | grep -v grep | awk '{print $2}'); do
        PIDS="$PIDS $f"
    done
fi

if [ -z "$PIDS" ]; then
    echo "Aucune instance de pilotage-deploiement en cours d'execution."
    exit 0
fi

echo "Arret des processus :$PIDS"
for p in $PIDS; do
    kill -9 "$p" 2>/dev/null
    # Sous Git Bash (MSYS) un processus Windows natif doit etre arrete via taskkill
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) taskkill //F //PID "$p" >/dev/null 2>&1 ;;
    esac
    if kill -0 "$p" 2>/dev/null; then
        echo "  echec de l'arret du processus $p." >&2
    else
        echo "  processus $p termine."
    fi
done
rm -f logs/app.pid logs/deploy.pid

for _ in $(seq 1 20); do
    if ! curl -s -o /dev/null "http://localhost:$PORT/actuator/health"; then
        echo "Port $PORT libere. Application arretee."
        exit 0
    fi
    sleep 1
done

echo "Le port $PORT repond encore, verifiez les processus residuels." >&2
exit 1