# Script de Restauration Logique MongoDB (`scripts/logical_restore.sh`)

Ce document décrit l'utilisation de [scripts/logical_restore.sh](../../scripts/logical_restore.sh) pour restaurer une archive logique créée par [scripts/logical_backup.sh](../../scripts/logical_backup.sh) (dont l'en-tête interne référence encore `mongodb_backup.sh` / `mongodb_restore.sh`).

## Table des Matières

* [Fonctionnalités](#fonctionnalités)
* [Avertissement de Sécurité](#avertissement-de-sécurité)
* [Prérequis](#prérequis)
* [Utilisation](#utilisation)
  * [Syntaxe Générale](#syntaxe-générale)
  * [Exemples d'Utilisation](#exemples-dutilisation)
* [Détails Techniques](#détails-techniques)
* [Considérations Importantes pour la Restauration](#considérations-importantes-pour-la-restauration)

## Fonctionnalités

* **Support Compressé et Chiffré** : Traite les archives `.tar.gz` et `.tar.gz.enc` (OpenSSL AES-256).
* **Décompression Temporaire** : Extrait l'archive dans un répertoire isolé sous `/tmp/` puis le nettoie en fin de script.
* **Détection `--oplogReplay`** : Détecte automatiquement les sauvegardes issues d'un replica set ou d'un cluster shardé via le nom d'archive pour activer `--oplogReplay`.
* **Option `--drop`** : Permet d'écraser les collections cibles existantes avant restauration.
* **Journalisation** : Écrit les traces dans `/var/log/mongodb/mongodb_restore.log` et sur la console.

## Avertissement de Sécurité

Ne stockez pas de mots de passe en clair dans des scripts versionnés. Utilisez l'authentification par fichier protégé (`0600`) ou un gestionnaire de secrets pour les environnements hors laboratoire.

## Prérequis

* **Système d'exploitation** : Linux Debian / Ubuntu (Ubuntu 24.04 recommandé).
* **Outils MongoDB** : `mongorestore`.
* **Outils Système** : `tar`, `gzip` et `openssl` (pour les archives `.enc`).
* **Permissions** : Lecture sur l'archive, écriture sous `/tmp/` et `/var/log/mongodb/`, et rôle MongoDB `restore` ou `dbAdminAnyDatabase` sur l'instance cible.

## Utilisation

```bash
sudo mkdir -p /var/log/mongodb
chmod +x scripts/logical_restore.sh
```

### Syntaxe Générale

```bash
bash ./scripts/logical_restore.sh <FICHIER_DE_SAUVEGARDE> <HOST_CIBLE> <PORT_CIBLE> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD] [--drop]
```

* `<FICHIER_DE_SAUVEGARDE>` : Chemin complet vers `.tar.gz` ou `.tar.gz.enc`.
* `<HOST_CIBLE>` : Hôte cible (nœud primaire pour un replica set, ou routeur `mongos` pour un cluster shardé).
* `<PORT_CIBLE>` : Port MongoDB cible.
* `[USERNAME]` / `[PASSWORD]` / `[AUTH_DB]` : Identifiants et base d'authentification (défaut `admin`).
* `[ENCRYPTION_PASSWORD]` : Secret requis si l'archive se termine par `.enc`.
* `[--drop]` : Supprime les collections cibles existantes avant restauration.

### Exemples d'Utilisation

1. **Restaurer une sauvegarde Standalone (non chiffrée)**

```bash
bash ./scripts/logical_restore.sh /var/backups/mongodb/standalone_localhost_27017_20250704_160000.tar.gz localhost 27017 admin myRestorePass admin
```

2. **Restaurer une sauvegarde Replica Set (chiffrée, avec `--drop`)**

```bash
bash ./scripts/logical_restore.sh /var/backups/mongodb/replicaset_rs0member1.example.com_27017_20250704_160000.tar.gz.enc rs0-primary.example.com 27017 admin myRestorePass admin myEncryptionKey --drop
```

3. **Restaurer une sauvegarde Sharded Cluster**

```bash
bash ./scripts/logical_restore.sh /var/backups/mongodb/sharded_mongos1.example.com_27020_20250704_160000.tar.gz mongos.example.com 27020 admin myRestorePass admin
```

## Détails Techniques

* **Activation automatique de `--oplogReplay`** : Le script inspecte le préfixe de l'archive (`replicaset_` ou `sharded_`) généré par `scripts/logical_backup.sh` afin de rejouer l'oplog sans perte de cohérence.
* **Nettoyage sous `/tmp/`** : Le répertoire temporaire est supprimé en fin d'opération, même en cas d'arrêt propre.

## Considérations Importantes pour la Restauration

* **Précaution sur `--drop`** : Vérifiez toujours la base cible avant d'utiliser `--drop` en raison du risque d'effacement irréversible.
* **Cible valide** : Restaurez exclusivement vers le `PRIMARY` d'un replica set ou un `mongos` sur cluster shardé.
* **Espace disque sous `/tmp/`** : Vérifiez que `/tmp/` dispose de l'espace libre nécessaire à la taille décompressée du dump.
* **Validation post-restauration** : Contrôlez les collections et le nombre de documents via `mongosh` après la restauration.
