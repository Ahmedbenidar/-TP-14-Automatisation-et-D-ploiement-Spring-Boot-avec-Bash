# TP 14 — Automatisation et déploiement Spring Boot avec Bash

Projet **pilotage-deploiement** : une petite API Spring Boot qui tient le registre des
livraisons (déploiements) d'une plateforme, accompagnée d'une **chaîne de scripts Bash**
qui automatise tout le cycle de vie : démarrage en arrière-plan, consultation des journaux,
contrôle de santé, construction du livrable, déploiement du JAR et sauvegarde des journaux.

Le but pédagogique du TP est de reproduire « à la main » ce que fait un outil de CI/CD :
écrire les commandes shell, comprendre `nohup`, la redirection `>` / `2>&1`, le `&`, la
variable `$!`, `ps` + `grep` + `awk`, `kill -9`, `chmod +x`, `tail` et `tar`.

## Ce que fait l'application

| Élément | Rôle |
|---|---|
| `Livraison` (entité JPA) | une livraison : composant, environnement, version, statut, durée |
| `LivraisonDepot` | repository Spring Data avec deux recherches dérivées |
| `LivraisonService` | amorce 5 livraisons de démonstration au démarrage (`@PostConstruct`) |
| `RegistreController` | 4 points d'entrée REST sous `/api/registre` |
| `index.html` | tableau de bord sombre qui consomme l'API |
| Spring Boot Actuator | `/actuator/health` : cible du script de supervision |

Points d'entrée REST :

- `GET /api/registre/livraisons` — toutes les livraisons
- `GET /api/registre/environnements/{env}` — filtre par environnement (`recette`, `production`)
- `GET /api/registre/statuts/{statut}` — filtre par statut (`SUCCES`, `ECHEC`)
- `GET /api/registre/synthese` — compteurs et durée moyenne

## Données de démonstration

| Composant | Environnement | Version | Statut | Durée |
|---|---|---|---|---|
| api-facturation | recette | 1.4.0 | SUCCES | 96 s |
| portail-agent | recette | 2.1.3 | SUCCES | 143 s |
| api-facturation | production | 1.3.7 | ECHEC | 38 s |
| portail-agent | production | 2.1.3 | SUCCES | 127 s |
| moteur-relances | recette | 0.9.2 | SUCCES | 74 s |

## Les six scripts

| Script | Rôle | Notions Bash travaillées |
|---|---|---|
| `scripts/demarrer.sh` | lance l'application en tâche de fond via `mvn spring-boot:run` | `nohup`, `>`, `2>&1`, `&`, `$!`, fichier de PID, boucle d'attente `curl` |
| `scripts/arreter.sh` | arrête l'instance (fichier de PID, puis `netstat`, puis `ps`/`grep`/`awk`) | `kill -0`, `kill -9`, `awk`, `netstat`, `taskkill` sous MSYS |
| `scripts/journaux.sh` | affiche les N dernières lignes du journal le plus récent | `ls -t`, `head -n 1`, `tail -n` |
| `scripts/deployer.sh` | `mvn clean package -DskipTests` puis `nohup java -jar` sur le JAR produit | `find`, `du -h`, `cut`, redirection, test de disponibilité |
| `scripts/sante.sh` | interroge `/actuator/health` et renvoie un code de sortie | `curl -s -m`, `grep -q`, codes de retour 0/1/2 |
| `scripts/sauvegarde-journaux.sh` | archive le dossier `logs/` avec un horodatage | `tar -czf`, `date +%Y%m%d-%H%M%S` |

Les scripts utilisent tous `set -u`, calculent leur racine avec
`RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` et sont exécutables
(`chmod +x scripts/*.sh`).

## Prérequis

- JDK 17 ou plus (testé avec JDK 21)
- Maven 3.9
- Un shell Bash : Linux, macOS, WSL ou **Git Bash** sous Windows
- `curl` (fourni avec Git Bash)

## Lancer le projet

Depuis un terminal Bash, à la racine du projet :

```bash
chmod +x scripts/*.sh

# 1. mode developpement (Maven)
./scripts/demarrer.sh
./scripts/sante.sh
./scripts/journaux.sh 20

# 2. mode production (JAR)
./scripts/arreter.sh
./scripts/deployer.sh
./scripts/sauvegarde-journaux.sh

# 3. arret
./scripts/arreter.sh
```

Application : <http://localhost:8110> — Santé : <http://localhost:8110/actuator/health>

### Sous Windows avec Git Bash

Ouvrir **Git Bash** (pas PowerShell), puis exporter Java et Maven si nécessaire :

```bash
export JAVA_HOME="/c/Program Files/Java/jdk-21"
export PATH="$JAVA_HOME/bin:/c/Users/<utilisateur>/tools/apache-maven-3.9.9/bin:$PATH"
```

Certains scripts détectent tout seuls `mvn` ou `mvn.cmd` (`command -v`). Sous MSYS,
`kill -9` n'arrête pas toujours un processus Windows natif : `arreter.sh` complète donc
avec `taskkill //F //PID`.

## Résultats obtenus

### 1. Tableau de bord de l'application démarrée

![Tableau de bord](docs/screenshots/01-application-demarree.png)

Après `./scripts/demarrer.sh`, l'application répond sur le port **8110**. Le tableau de
bord affiche les trois compteurs calculés par `/api/registre/synthese` — 5 livraisons
enregistrées, 4 réussies, 96 secondes de durée moyenne — et le détail des cinq livraisons
avec un badge vert pour les succès et rouge pour l'échec.

### 2. API REST des livraisons

![API livraisons](docs/screenshots/02-api-livraisons.png)

`GET /api/registre/livraisons` renvoie le JSON complet des cinq livraisons triées par
horodatage. C'est cette réponse que le tableau de bord consomme en JavaScript.

### 3. Sonde de santé Actuator

![Actuator health](docs/screenshots/03-actuator-health.png)

`/actuator/health` expose l'état de la base H2, de l'espace disque et du ping applicatif.
C'est la cible du script `sante.sh`, qui cherche la chaîne `"status":"UP"` et renvoie
le code de sortie 0 quand le service est opérationnel (utilisable tel quel dans un cron
ou dans un pipeline).

### 4. Scripts de supervision exécutés pour de vrai

![Scripts sante et journaux](docs/screenshots/04-scripts-sante-journaux.png)

Fenêtre de console réelle : `sante.sh` affiche l'URL interrogée, la réponse brute et son
verdict, puis `journaux.sh` affiche les dernières lignes de `logs/app.log` et l'état du
fichier de PID. On y voit la ligne `Started PilotageApplication in 6.61 seconds` et
`Tomcat started on port 8110`.

### 5. Cycle complet arrêt → déploiement du JAR

![Cycle de deploiement](docs/screenshots/05-cycle-deploiement.png)

`arreter.sh` arrête l'instance Maven, `deployer.sh` nettoie et recompile le projet
(`mvn -B -q clean package -DskipTests`), affiche la taille du livrable produit, lance
`nohup java -jar target/pilotage-deploiement.jar` et attend que le port réponde avant
d'annoncer `Deploiement termine`. Le `tasklist` final confirme qu'un seul processus
`java.exe` sert l'application.

### 6. Sauvegarde horodatée des journaux

![Sauvegarde des journaux](docs/screenshots/06-sauvegarde-journaux.png)

`sauvegarde-journaux.sh` crée `archives/journaux_AAAAMMJJ-HHMMSS.tar.gz`. La capture
montre l'archive créée, son contenu (`logs/app.log`, `logs/deploy.log`, les fichiers de
PID), la taille de chaque archive déjà présente et la liste des scripts du projet.

Les sorties texte complémentaires (arborescence, réponses JSON, contenu des archives)
sont conservées dans [`docs/captures/`](docs/captures).

## Choix d'implémentation

- **Port 8110** au lieu du 8080 par défaut, pour éviter tout conflit avec les autres TP.
- **Pas de profil Maven** : le même `pom.xml` sert au mode développement et au mode
  production ; c'est le script qui choisit `spring-boot:run` ou `java -jar`.
- **`finalName` fixé** à `pilotage-deploiement` : le script de déploiement retrouve son
  JAR de manière déterministe, sans dépendre du numéro de version.
- **Fichiers de PID** dans `logs/` (`app.pid` pour Maven, `deploy.pid` pour le JAR) :
  chaque script sait exactement quelle instance il pilote.
- **Base H2 en mémoire** avec `ddl-auto=create` et un amorçage `@PostConstruct` : le TP
  porte sur Bash, pas sur la persistance, donc aucun schéma à installer.
- **Scripts idempotents** : `demarrer.sh` refuse de démarrer deux fois, `arreter.sh`
  sort proprement en code 0 s'il n'y a rien à arrêter, `sauvegarde-journaux.sh` crée le
  dossier `archives/` si besoin.

## Personnalisation par rapport à l'énoncé

| Énoncé | Réalisation |
|---|---|
| Groupe `ma.ens` | `ma.usmba` |
| Artefact `springbash` | `pilotage-deploiement` |
| Dossier `ens-springbash/` | `tp14_pilotage_bash/` |
| Package `ma.ens.springbash` | `ma.usmba.tp14.registre` |
| Port `8085` | **8110** |
| `run.sh` | `demarrer.sh` |
| `stop.sh` | `arreter.sh` |
| `deploy.sh` | `deployer.sh` |
| `logs.sh` | `journaux.sh` |
| `healthcheck.sh` | `sante.sh` |
| `tar -czf logs_$(date +%Y%m%d).tar.gz logs/` | `sauvegarde-journaux.sh` avec `journaux_%Y%m%d-%H%M%S.tar.gz` |
| Application vide | registre des livraisons (JPA + H2 + Actuator + tableau de bord) |

## Structure du projet

```
tp14_pilotage_bash/
├── pom.xml
├── scripts/
│   ├── demarrer.sh
│   ├── arreter.sh
│   ├── journaux.sh
│   ├── deployer.sh
│   ├── sante.sh
│   └── sauvegarde-journaux.sh
├── src/main/java/ma/usmba/tp14/registre/
│   ├── PilotageApplication.java
│   ├── modele/Livraison.java
│   ├── depot/LivraisonDepot.java
│   ├── service/LivraisonService.java
│   └── web/RegistreController.java
├── src/main/resources/
│   ├── application.properties
│   └── static/index.html
└── docs/
    ├── captures/
    └── screenshots/
```
