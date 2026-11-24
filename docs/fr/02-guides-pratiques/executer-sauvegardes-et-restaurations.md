# Exécuter les Sauvegardes Logiques et PITR

Utilisez cette procédure pour créer, vérifier et restaurer les sauvegardes logiques ou incrémentielles.

## Prérequis

- Vérifiez que `mongosh`, `mongodump`, `mongorestore`, `tar` et `openssl` sont installés.
- Vérifiez que le compte MongoDB possède les rôles `backup`, `restore` et `clusterMonitor`.

NOTE: Consultez la syntaxe des scripts dans [Référence des scripts et anomalies](../03-reference/scripts-compose-et-anomalies.md).

## Procédure

### Créer une Archive Logique (`scripts/logical_backup.sh`)

1. Créez le dossier `/var/backups/mongodb` pour autoriser la redirection de log à la ligne `26` :

```bash
sudo mkdir -p /var/backups/mongodb
```

2. Exécutez `scripts/logical_backup.sh` sur votre topologie cible :

```bash
bash ./scripts/logical_backup.sh replicaset localhost 27017 admin strongpass admin
```

### Exécuter une Sauvegarde PITR (`scripts/backups_pitr/mongo_backup.sh`)

1. Activez `MONGO_USER`, `MONGO_PASS` et le bloc `AUTH_OPTIONS` dans `scripts/backups_pitr/mongo_backup.sh`.
2. Exécutez une sauvegarde complète initiale :

```bash
bash ./scripts/backups_pitr/mongo_backup.sh full
```

3. Exécutez une sauvegarde incrémentielle après les écritures en base :

```bash
bash ./scripts/backups_pitr/mongo_backup.sh incremental
```

## Vérification

Vérifiez la présence des archives, des empreintes SHA-256 et du journal :

```bash
ls -lh /var/backups/mongodb/*.tar.gz* /var/backups/mongodb/*.sha256
tail -n 20 /var/backups/mongodb/mongodb_backup.log
```

Si vous utilisez les sauvegardes PITR, examinez `oplog_timestamp.txt` et les sous-dossiers `inc_*` :

```bash
ls -la /data/mongodb_backups/full /data/mongodb_backups/incremental
cat /data/mongodb_backups/oplog_timestamp.txt
```

## Retour Arrière

ATTENTION: Retirez `--drop` tant que la cible reste incertaine. L'option `--drop` supprime les collections actuelles avant la restauration.

1. Créez `/var/log/mongodb` pour la redirection de log à la ligne `24` de `scripts/logical_restore.sh` :

```bash
sudo mkdir -p /var/log/mongodb
```

2. Restaurez une archive logique avec `scripts/logical_restore.sh` :

```bash
bash ./scripts/logical_restore.sh /var/backups/mongodb/<archive>.tar.gz localhost 27017 admin strongpass admin
```

3. Pour PITR, activez `MONGO_RESTORE_USER`, `MONGO_RESTORE_PASS` et `AUTH_OPTIONS` dans `scripts/backups_pitr/mongo_restore.sh`, puis exécutez la restauration :

```bash
bash ./scripts/backups_pitr/mongo_restore.sh <FULL_TIMESTAMP>
```

Consultez l'analyse des choix dans [Architecture des topologies et sauvegardes](../04-explications/architecture-topologies-et-sauvegardes.md).
