# Référence des Scripts, Topologies Compose et Anomalies

Inventaire vérifié des piles Docker, scripts Bash, jeux de données, playbooks Ansible et défauts amont du dépôt **mongodb-training**.

## Topologies Docker Compose

| Chemin | Services | Ports par défaut | Variables / Secrets |
| :--- | :--- | :--- | :--- |
| `docker/standalone/compose.yaml` | `mongo`, `mongo-express` | `27017`, `8081` | Variables intégrées (`root` / `admin1`, `ME_CONFIG_BASICAUTH: false`) |
| `docker/sharded/docker-compose.yml` | `config-server-1..3`, `shard1-replica-1..3`, `shard2-replica-1..3`, `mongos-router-1..2`, `mongo-setup` | `27019`–`27021` (config), `27022`–`27027` (shards), `27017`–`27018` (`mongos`) | `docker/sharded/.env_example` (`MONGO_VERSION=7.0`), `data/config/mongod.conf` |

## Scripts Bash (`scripts/` et `docker/sharded/init-scripts/`)

| Chemin | Nom en en-tête | Paramètres / Comportement | Notes |
| :--- | :--- | :--- | :--- |
| `scripts/install_mongodb_8.0.sh` | — | Installe le dépôt et paquets MongoDB `8.0` sous Ubuntu `noble` | Exécution avec privilèges `sudo` |
| `scripts/create_instance.sh` | `setup_mongodb_instance.sh` | `<NUMERO_INSTANCE>` (`port = 27016 + N`) | Crée `/etc/mongod/instanceN.conf`, `keyfile` et service `systemd` |
| `scripts/create_arbitrer.sh` | `setup_mongodb_arbiter.sh` | `<NUMERO_INSTANCE>` | Coquille dans le nom de fichier (`arbitrer`) |
| `scripts/create_mongos.sh` | `setup_mongodb_mongos.sh` | `<NUMERO_MONGOS> <CFG_RS>/<HOSTS>` | **Échoue à `bash -n` à la ligne `230`** (chaîne non fermée) |
| `scripts/rm_mongodb_instance.sh` | `uninstall_mongodb_instance.sh` | `<NUMERO_INSTANCE>` | Arrête et purge l'instance |
| `scripts/create_admin_user.sh` | `create_mongodb_admin.sh` | `<PORT_MONGODB>` | Crée `admin` / `admin` avec rôle `root` |
| `scripts/create_db_users.sh` | `generate_mongodb_users.sh` | `<NOM_DB> [FICHIER_SORTIE]` | Utilise `pwgen` pour `ReadOnly`, `ReadWrite` et `Owner` |
| `scripts/create_aliases.sh` | `generate_mongo_aliases.sh` | `[USER] [PASS] [AUTH_DB]` | Génère `~/.bashrc_mongodb` selon `/etc/mongod/*.conf` |
| `scripts/inject_sample_databses.sh` | — | `--repo-url`, `--mongo-db`, `--mongo-collection`, options host/port/auth | Clone un dépôt Git et exécute `mongoimport` (`databses`) |
| `scripts/logical_backup.sh` | `mongodb_backup.sh` | `<standalone\|replicaset\|sharded> <HOST> <PORT> [USER] [PASS] [AUTH_DB] [ENC_PASS]` | Ligne `26` redirige vers le log avant le `mkdir -p` de la ligne `35` |
| `scripts/logical_restore.sh` | `mongodb_restore.sh` | `<ARCHIVE> <HOST> <PORT> [USER] [PASS] [AUTH_DB] [ENC_PASS] [--drop]` | Ligne `24` écrit `/var/log/mongodb/mongodb_restore.log` sans `mkdir -p`; active `--oplogReplay` sur `replicaset_*` / `sharded_*` |
| `scripts/backups_pitr/mongo_backup.sh` | — | `<full\|incremental>` | Sauvegardes PITR oplog sous `/data/mongodb_backups/`; bloc `AUTH_OPTIONS` commenté (`L84-87`) |
| `scripts/backups_pitr/mongo_restore.sh` | — | `<FULL_TIMESTAMP_DIR>` | Rejoue `full` (`--drop`) puis `inc_*` triés; bloc `AUTH_OPTIONS` commenté (`L69-72`) |
| `scripts/pitr_backup.sh` | — | `<full\|incremental>` | Copie quasi identique de `scripts/backups_pitr/mongo_backup.sh` (`AUTH_OPTIONS` aussi commenté) |
| `docker/sharded/init-scripts/init-datadir.sh` | — | Sans argument | Crée `data/config1..3`, `shard1-1..3`, `shard2-1..3` |
| `docker/sharded/init-scripts/init-keyfile.sh` | — | Lit `$MONGO_REPLICA_SET_KEY` | Écrit `./data/keyfile/mongodb-keyfile` (`chmod 600`, `chown 999:999` sous `sudo`) |
| `docker/sharded/init-scripts/init-cluster.sh` | — | Point d'entrée `mongo-setup` | Attend 30s puis exécute `init-replica-sets.js` et `init-users.js` |

## Jeux de Données et Playbooks Ansible

| Fichier | Format | Description |
| :--- | :--- | :--- |
| `datasets/books.json` | NDJSON | `150` documents livres (JSON délimité par ligne pour `mongoimport`) |
| `datasets/orders.json` | NDJSON | `1 000` documents commandes |
| `datasets/stocks.json` | NDJSON | `42` documents stocks |
| `datasets/import.sh` | Bash | Exécute `mongoimport --username="admin" --authenticationDatabase="admin" --db=test --port 27018` |
| `playbooks/add_swapfile.yaml` | Ansible YAML | Provisionnement d'un fichier d'échange Linux |
| `playbooks/install_docker.yaml` | Ansible YAML | Installation de Docker Engine et Compose sur Ubuntu |
| `playbooks/install_mongod.yaml` | Ansible YAML | Installation des paquets MongoDB `8.0` sous Ubuntu `noble` |
| `playbooks/config_system.yml` | Ansible YAML | **YAML invalide ligne `181`** (tâche `Firewall \| SSH` sur-indentée après la ligne `172`) |
| `playbooks/run_script.yaml` | Ansible YAML | Playbook historique ciblant `mysql` (`hosts: "{{target\| default('mysql')}}"`) |
| `inventory/hosts.ini` & `ansible.cfg` | INI | Groupes `app`, `mongodb`, `proxy`; clé configurée vers `~/GIT_REPOS/vmscripts/vms/id_rsa` |

## Anomalies Amont Vérifiées

| Sévérité | Emplacement | Comportement observé |
| :--- | :--- | :--- |
| Élevée | `scripts/create_mongos.sh:L230` | Chaîne tronquée provoquant une erreur `unexpected EOF` à `bash -n` |
| Élevée | `playbooks/config_system.yml:L181` | Indentation à 8 espaces rejetée par `yaml.safe_load` |
| Élevée | `scripts/logical_backup.sh:L26` | Redirection `tee` appelée avant `mkdir -p` (`L35`) |
| Élevée | `scripts/logical_restore.sh:L20-24` | Redirection vers `/var/log/mongodb/mongodb_restore.log` sans création de `/var/log/mongodb` |
| Moyenne | `scripts/backups_pitr/mongo_*.sh` | Blocs conditionnels `AUTH_OPTIONS` (`L84-87`, `L69-72`) commentés même après saisie des identifiants |
| Moyenne | `docker/sharded/docker-compose.yml:L10-55` | `--auth` commenté sur `config-server-1..3` |
| Moyenne | `docker/sharded/init-scripts/*.js` | Mots de passe écrits en dur au lieu de lire `process.env` |
| Faible | `scripts/pitr_backup.sh` | Duplication à 2 commentaires près avec `scripts/backups_pitr/mongo_backup.sh` |
