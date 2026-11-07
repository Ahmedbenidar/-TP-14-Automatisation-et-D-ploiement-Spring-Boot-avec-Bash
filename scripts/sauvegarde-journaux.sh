#!/usr/bin/env bash
# Archive les journaux applicatifs dans une archive horodatee
set -u

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 1
mkdir -p archives

if [ ! -d logs ]; then
    echo "Aucun dossier logs : rien a archiver." >&2
    exit 1
fi

NOM="archives/journaux_$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$NOM" logs/

echo "Archive creee : $NOM ($(du -h "$NOM" | cut -f1))"
echo "Contenu :"
tar -tzf "$NOM" | sed 's/^/  - /'