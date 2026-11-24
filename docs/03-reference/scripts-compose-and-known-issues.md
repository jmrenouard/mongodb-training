# Scripts, Compose Topologies, and Known Issues Reference

Verified inventory of container definitions, automation scripts, datasets, Ansible playbooks, and known upstream issues inside **mongodb-training**.

## Docker Compose Topologies

| Stack Path | Services | Default Ports | Configuration / Secrets Source |
| :--- | :--- | :--- | :--- |
| `docker/standalone/compose.yaml` | `mongo`, `mongo-express` | `27017`, `8081` | Inline env (`root` / `admin1`; `ME_CONFIG_BASICAUTH: false`) |
| `docker/sharded/docker-compose.yml` | `config-server-1..3`, `shard1-replica-1..3`, `shard2-replica-1..3`, `mongos-router-1..2`, `mongo-setup` | `27019`–`27021` (config), `27022`–`27027` (shards), `27017`–`27018` (`mongos`) | `docker/sharded/.env_example` (`MONGO_VERSION=7.0`), `data/config/mongod.conf` |

## Shell Scripts Inventory (`scripts/` and `docker/sharded/init-scripts/`)

| Path | Internal Comment Name | CLI Parameters / Behavior | Notes |
| :--- | :--- | :--- | :--- |
| `scripts/install_mongodb_8.0.sh` | — | Installs MongoDB `8.0` repo/packages on Ubuntu `noble` | Root / `sudo` APT setup |
| `scripts/create_instance.sh` | `setup_mongodb_instance.sh` | `<INSTANCE_NUM>` (`port = 27016 + N`) | Writes `/etc/mongod/instanceN.conf`, keyfile, `systemd` template |
| `scripts/create_arbitrer.sh` | `setup_mongodb_arbiter.sh` | `<INSTANCE_NUM>` | Filename typo (`arbitrer`) |
| `scripts/create_mongos.sh` | `setup_mongodb_mongos.sh` | `<MONGOS_NUM> <CFG_RS>/<HOSTS>` | **Fails `bash -n` at `L230`** (truncated string) |
| `scripts/rm_mongodb_instance.sh` | `uninstall_mongodb_instance.sh` | `<INSTANCE_NUM>` | Stops and deletes instance files |
| `scripts/create_admin_user.sh` | `create_mongodb_admin.sh` | `<PORT>` | Creates `admin` / `admin` (`root` role) |
| `scripts/create_db_users.sh` | `generate_mongodb_users.sh` | `<DB_NAME> [OUT_JS_FILE]` | Uses `pwgen` for ReadOnly/ReadWrite/Owner |
| `scripts/create_aliases.sh` | `generate_mongo_aliases.sh` | `[USER] [PASS] [AUTH_DB]` | Writes `~/.bashrc_mongodb` per `/etc/mongod/*.conf` |
| `scripts/inject_sample_databses.sh` | — | `--repo-url`, `--mongo-db`, `--mongo-collection`, optional host/port/auth | Clones Git repo and runs `mongoimport`; filename typo (`databses`) |
| `scripts/logical_backup.sh` | `mongodb_backup.sh` | `<standalone\|replicaset\|sharded> <HOST> <PORT> [USER] [PASS] [AUTH_DB] [ENC_PASS]` | `exec > >(tee ...)` at `L26` precedes `mkdir -p` at `L35` |
| `scripts/logical_restore.sh` | `mongodb_restore.sh` | `<ARCHIVE> <HOST> <PORT> [USER] [PASS] [AUTH_DB] [ENC_PASS] [--drop]` | Auto-enables `--oplogReplay` on `replicaset_*` / `sharded_*` archives |
| `scripts/backups_pitr/mongo_backup.sh` | — | `<full\|incremental>` | Oplog PITR backups under `/data/mongodb_backups/` |
| `scripts/backups_pitr/mongo_restore.sh` | — | `<FULL_TIMESTAMP_DIR>` | Replays `full` (`--drop`) then sorted `inc_*` `oplog.bson` |
| `scripts/pitr_backup.sh` | — | `<full\|incremental>` | Near-duplicate of `scripts/backups_pitr/mongo_backup.sh` (`-2` comment lines) |
| `docker/sharded/init-scripts/init-datadir.sh` | — | No arguments | Creates `data/config1..3`, `shard1-1..3`, `shard2-1..3` |
| `docker/sharded/init-scripts/init-keyfile.sh` | — | Requires `$MONGO_REPLICA_SET_KEY` | Writes `./data/keyfile/mongodb-keyfile` (`chmod 400`) |
| `docker/sharded/init-scripts/init-cluster.sh` | — | Container entrypoint | Waits 30s, invokes `init-replica-sets.js` then `init-users.js` |

## Datasets and Ansible Playbooks

| File | Format | Details |
| :--- | :--- | :--- |
| `datasets/books.json` | NDJSON | `150` book documents (`mongoimport` line-delimited JSON) |
| `datasets/orders.json` | NDJSON | `1,000` order documents |
| `datasets/stocks.json` | NDJSON | `42` stock documents |
| `datasets/import.sh` | Bash | Runs `mongoimport --username="admin" --authenticationDatabase="admin" --db=test --port 27018` |
| `playbooks/add_swapfile.yaml` | Ansible YAML | Adds Linux swapfile |
| `playbooks/install_docker.yaml` | Ansible YAML | Installs Docker CE / Compose on Ubuntu |
| `playbooks/install_mongod.yaml` | Ansible YAML | Installs MongoDB `8.0` server & tools on Ubuntu `noble` |
| `playbooks/config_system.yml` | Ansible YAML | **Invalid YAML at `L181`** (`Firewall \| SSH` task over-indented below `L172`) |
| `playbooks/run_script.yaml` | Ansible YAML | Legacy MySQL script-runner (`hosts: "{{target\| default('mysql')}}"`) |
| `inventory/hosts.ini` & `ansible.cfg` | INI | Groups `app`, `mongodb` (`dbsrv1..3`), `proxy`; `ansible.cfg` points key to `~/GIT_REPOS/vmscripts/vms/id_rsa` |

## Known Upstream Issues Matrix

| Severity | Location | Verified Behavior |
| :--- | :--- | :--- |
| High | `scripts/create_mongos.sh:L230` | Truncated string causes `bash -n` syntax failure (`unexpected EOF`) |
| High | `playbooks/config_system.yml:L181` | Invalid 8-space task indentation fails `yaml.safe_load` |
| High | `scripts/logical_backup.sh:L26` | Log redirection executes before `mkdir -p` (`L35`) |
| Medium | `docker/sharded/docker-compose.yml:L10-55` | `--auth` is commented out on `config-server-1..3` |
| Medium | `docker/sharded/init-scripts/*.js` | Hardcodes training passwords instead of reading `process.env` |
| Low | `scripts/pitr_backup.sh` | Unsynced copy of `scripts/backups_pitr/mongo_backup.sh` |
