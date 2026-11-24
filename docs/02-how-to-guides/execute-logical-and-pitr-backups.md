# How to Run Logical and PITR Backups

Use this procedure to create, verify, and restore logical dumps or PITR oplog backups.

## Prerequisites

- Confirm `mongosh`, `mongodump`, `mongorestore`, `tar`, and `openssl` are installed on the host.
- Confirm the MongoDB user holds `backup`, `restore`, and `clusterMonitor` roles.

NOTE: Review script parameters and defaults in [Scripts, Compose, and Known Issues Reference](../03-reference/scripts-compose-and-known-issues.md).

## Procedure

### Create Logical Archives (`scripts/logical_backup.sh`)

1. Create `/var/backups/mongodb` so log redirection succeeds on line `26` of `scripts/logical_backup.sh`:

```bash
sudo mkdir -p /var/backups/mongodb
```

2. Run `scripts/logical_backup.sh` against your target topology:

```bash
bash ./scripts/logical_backup.sh replicaset localhost 27017 admin strongpass admin
```

### Run Oplog PITR Backups (`scripts/backups_pitr/mongo_backup.sh`)

1. Edit `BACKUP_DIR`, `MONGO_HOST`, `MONGO_PORT`, `MONGO_USER`, and `MONGO_PASS` in `scripts/backups_pitr/mongo_backup.sh`.
2. Create a baseline full backup first:

```bash
bash ./scripts/backups_pitr/mongo_backup.sh full
```

3. Run an incremental oplog backup after database writes occur:

```bash
bash ./scripts/backups_pitr/mongo_backup.sh incremental
```

## Validation

Verify generated logical archives, SHA-256 checksums, and backup log files:

```bash
ls -lh /var/backups/mongodb/*.tar.gz* /var/backups/mongodb/*.sha256
tail -n 20 /var/backups/mongodb/mongodb_backup.log
```

For PITR backups, inspect `oplog_timestamp.txt` and `inc_*` subdirectories under `/data/mongodb_backups/`:

```bash
ls -la /data/mongodb_backups/full /data/mongodb_backups/incremental
cat /data/mongodb_backups/oplog_timestamp.txt
```

## Rollback

CAUTION: Keep `--drop` off until you confirm the target database because `--drop` deletes stored collections permanently.

1. Restore a logical archive to a target node with `scripts/logical_restore.sh`:

```bash
bash ./scripts/logical_restore.sh /var/backups/mongodb/<archive>.tar.gz localhost 27017 admin strongpass admin
```

2. Restore a PITR chain from a full backup timestamp with `scripts/backups_pitr/mongo_restore.sh`:

```bash
bash ./scripts/backups_pitr/mongo_restore.sh <FULL_TIMESTAMP>
```

Read design trade-offs in [Topology and Backup Architecture](../04-explanation/topology-and-backup-architecture.md).
