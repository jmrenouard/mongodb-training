# Guide exhaustif du fichier `mongod.conf`

Au cœur de toute instance MongoDB auto-hébergée, le fichier YAML `mongod.conf` pilote le comportement du démon `mongod`. Comprendre chaque section, ses paramètres clés et leurs implications en matière d’authentification, de sécurité, de réplication et de sharding est indispensable pour déployer une base robuste et sûre[1].

## 🗂️ Structure générale du fichier

```yaml
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log

storage:
  dbPath: /var/lib/mongo
  engine: wiredTiger

net:
  port: 27017
  bindIp: 127.0.0.1

security:
  authorization: enabled
  keyFile: /opt/mongo/keyfile

replication:
  replSetName: rs0
  oplogSizeMB: 10240

sharding:
  clusterRole: shardsvr
```

Chaque bloc de premier niveau correspond à un domaine fonctionnel ; les sous-clés affinent le comportement du serveur[2].

## 📑 Journalisation – `systemLog`

| Clé | Rôle | Bonnes pratiques |
|-----|------|------------------|
| `destination` | `file` ou `syslog` pour écrire localement ou via *syslog* | Utiliser *syslog* pour centraliser les traces[3] |
| `path` | Chemin du fichier log en mode `file` | Stockage sur volume dédié haute endurance |
| `logAppend` | `true` pour append, `false` pour overwrite | Toujours `true` en production pour conserver l’historique[4] |
| `verbosity` | Niveau 0–5 (FATAL→DEBUG) | Laisser 0 ; n’augmenter que temporairement |

## 💾 Stockage – `storage`

| Clé | Description | Avantages | Inconvénients |
|-----|-------------|-----------|---------------|
| `dbPath` | Répertoire des fichiers de données | Séparation données / OS[5] | Exige droits d’écriture dédiés |
| `engine` | `wiredTiger` (défaut), `inMemory`, etc.[6] | Compression & transactions | Consommation RAM supérieure |
| `journal.enabled` | Force l’écriture journaux | Intégrité après crash | Overhead disque |
| `wiredTiger.engineConfig.cacheSizeGB` | Taille du cache | Contrôle l’empreinte mémoire | Nécessite tuning par charge |

**⚠️ Points de vigilance**  
-  Sur disque partagé, activer le *journal* pour éviter la corruption après panne[6].  
-  `directoryPerDB: true` isole chaque base dans un dossier, simplifiant les sauvegardes incrémentales.

## 🌐 Réseau – `net`

| Paramètre | Usage | Risques |
|-----------|-------|---------|
| `port` | Changer le port par défaut évite les scans automatisés[7] | Nécessite mise à jour des clients |
| `bindIp` | Liste d’IP écoutées | Limiter à l’IP privée du service ; bannir `0.0.0.0` sans firewall[8] |
| `tls:` | Sous-bloc pour TLS/SSL (`mode`, `certificateKeyFile`, `CAFile`) | Chiffre le trafic ; obligatoire en production[9] |

## 🔐 Sécurité – `security`

### Authentification & Autorisation

| Clé | Effet | Notes |
|-----|-------|-------|
| `authorization: enabled` | Active le contrôle RBAC[10] | Exige des comptes administrateurs[11] |
| `keyFile` | Clé partagée pour authentifier les nœuds du replica set[12] | 600 droits UNIX, ≥ 6 octets aléatoires |
| `clusterAuthMode` | `keyFile` / `sendKeyFile` / `x509`[12] | `x509` recommandé pour clusters multi-org |

### Chiffrement au repos

```yaml
security:
  enableEncryption: true
  encryptionKeyFile: /opt/mongo/enc-key
```

Active l’AES-256 du moteur WiredTiger ; associer idéalement un coffre-fort KMIP[13].

### Audit

```yaml
security:
  auditLog:
    destination: file
    path: /var/log/mongodb/audit.json
    format: JSON
```

Trace les actions sensibles : création d’utilisateurs, changements de rôle[14][15].

## 🔁 Réplication – `replication`

| Paramètre | Description | Recommandations |
|-----------|-------------|-----------------|
| `replSetName` | Nom du replica set, identique sur tous les nœuds[16] | Obligatoire pour la haute dispo |
| `enableMajorityReadConcern` | Garantit des lectures causales[17] | Laisser `true` ; `false` seulement pour anciens clusters |
| `oplogSizeMB` | Taille de l’oplog en MB[18][19] | ≥ 24 h d’activité ; ajuster selon volume |

**⚠️ Points de vigilance**  
-  Une oplog trop petite déclenche l’erreur *RS102 too stale to catch up*[18].  
-  Toujours initialiser le premier utilisateur **avant** d’activer `authorization` pour éviter le verrouillage[11].

## 🗃️ Sharding – `sharding`

| Clé | Valeur | Commentaire |
|-----|--------|-------------|
| `clusterRole` | `configsvr`, `shardsvr` ou `mongos`[20][21] | Définit la fonction du processus |
| `archiveMovedChunks` | `true` (défaut) pour archiver les documents migrés[22] | Peut remplir le disque ; surveiller |

Le balancer s’exécute depuis le *config server primary* et migre les *chunks* pour équilibrer la charge[22].

## ⚙️ Gestion du processus – `processManagement`

| Clé | Usage | Conseils |
|-----|-------|----------|
| `fork: true` | *Daemonize* en arrière-plan sur SysV[7] | Inutile sous systemd, peut causer un échec d’amorçage[23] |
| `pidFilePath` | Fichier PID lorsque `fork: true` | S’autogère via systemd ; sinon obligatoire |

## 📊 Tableau récapitulatif des sections critiques

| Section | Paramètres clés | Avantages | Inconvénients / Risques |
|---------|-----------------|-----------|-------------------------|
| `systemLog` | `destination`, `path`, `verbosity` | Traçabilité | Volume log important |
| `storage` | `engine`, `cacheSizeGB` | Performance | Besoin tuning |
| `net` | `bindIp`, `tls.*` | Sécurité réseau | Complexité certifs |
| `security` | `authorization`, `keyFile`, `enableEncryption` | Conformité RGPD | Gestion clés sensible |
| `replication` | `replSetName`, `oplogSizeMB` | Haute dispo | Latence si mal configuré |
| `sharding` | `clusterRole` | Scalabilité horizontale | Complexité opérationnelle |

## 💻 Exemples de commandes d’administration

```bash
# Démarrage avec fichier de configuration
mongod --config /etc/mongod.conf

# Création d’un utilisateur admin
mongosh --eval '
  use admin;
  db.createUser({
    user: "root",
    pwd: passwordPrompt(),
    roles:[{role:"root",db:"admin"}]
  })
'

# Vérifier la configuration courante
mongosh --eval 'db.adminCommand({getCmdLineOpts:1})' --authenticationDatabase admin -u root -p
```

## ⚠️ Points de vigilance

1. Ne jamais exposer `bindIp: 0.0.0.0` sans pare-feu ; préférer VPN ou bastion[8].  
2. Toujours restreindre les privilèges utilisateurs via des rôles granulaires[24].  
3. Sur sharding, vérifier que chaque processus possède la *clusterRole* correcte, faute de quoi les commandes shard échouent[20][21].  
4. Sauvegarder et surveiller la santé du replica set avant toute modification de l’oplog ou du moteur de stockage[25].

## ✅ Conclusion

Un fichier `mongod.conf` bien rédigé conjugue **authentification forte**, **chiffrement**, **journalisation exhaustive**, **réplication tolérante aux pannes** et **sharding équilibré**, tout en restant lisible pour l’équipe d’exploitation. Adapter méticuleusement chaque paramètre au contexte métier garantit à la fois performance et sécurité pérennes de vos déploiements MongoDB[1][7].

[1] https://www.mongodb.com/docs/manual/reference/configuration-options/
[2] https://www.mongodb.com/docs/manual/reference/configuration-file-settings-command-line-options-mapping/
[3] https://serverfault.com/questions/966582/writing-mongodb-logs-to-a-remote-logging-server
[4] https://stackoverflow.com/questions/56309854/mongodb-unrecognized-option-systemlog
[5] https://www.technodba.com/2022/10/mongodbconfigandlogfile.html
[6] https://www.mongodb.com/docs/manual/core/wiredtiger/
[7] https://www.mongodb.com/docs/manual/reference/program/mongod/
[8] https://www.programmevitam.fr/ressources/Doc6.RC/html/exploitation/composants/mongo/2mongod/configuration.html
[9] https://www.mydbops.com/blog/securing-mongodb-cluster-with-tls-ssl
[10] https://stackoverflow.com/questions/25325142/how-to-set-authorization-in-mongodb-config-file
[11] https://www.mongodb.com/docs/manual/tutorial/enable-authentication/
[12] https://stackoverflow.com/questions/73350467/need-information-on-mongodb-security-config-options-mongodb-4-2
[13] https://www.docs4dev.com/docs/en/mongodb/v3.6/reference/tutorial-configure-encryption.html
[14] https://docs.percona.com/percona-server-for-mongodb/7.0/audit-logging.html
[15] https://www.swiftorial.com/swiftlessons/mongodb/security-best-practices/auditing-and-logging-in-mongodb/
[16] https://www.thegeekstuff.com/2014/02/mongodb-replication/
[17] https://stackoverflow.com/questions/69617008/mongodb-majority-read-concern
[18] https://serverfault.com/questions/550887/changing-mongodb-oplog-size
[19] https://docs.huihoo.com/mongodb/3.4/core/replica-set-oplog/index.html
[20] https://stackoverflow.com/questions/63395746/mongodb-unrecognized-option-clusterrole
[21] https://www.mongodb.com/community/forums/t/failed-to-refresh-session-cache-shardingstatenotinitialized-cannot-accept-sharding-commands-if-sharding-state-has-not-been-initialized-with-a-shardidentity-document/179462/2
[22] https://www.mongodb.com/ko-kr/docs/v4.4/core/sharding-balancer-administration/
[23] https://www.mongodb.com/community/forums/t/what-is-the-use-of-mongodb-pid-file-and-what-is-its-relevance-in-regards-to-fork-option/217163
[24] https://www.percona.com/blog/mongodb-101-5-configuration-options-that-impact-security-and-how-to-set-them/
[25] https://docs.percona.com/percona-server-for-mongodb/4.0/switch-storage-engines.html
[26] https://www.mongodb.com/community/forums/t/cannot-add-authorization-enable-to-mongod-conf-yaml-ccp-error/174664
[27] https://docs.anaconda.com/anaconda-repository/admin-guide/install/config/config-mongodb-authentication/
[28] https://github.com/mongodb/mongo/wiki/Sharding-Internals/ea79e3172b630d02be84d20c804c25fd20fced28
[29] https://www.mysoftkey.com/mongodb/mongod-conf-yaml-file-format-example/
[30] https://www.mongodb.com/docs/manual/tutorial/configure-ssl/
[31] https://www.mongodb.com/docs/manual/tutorial/configure-ssl-clients/
[32] https://www.mongodb.com/docs/manual/core/security-transport-encryption/
[33] https://mongoc.org/libmongoc/1.24.3/configuring_tls.html
[34] https://docs-atlas-staging.mongodb.com/reference/api/encryption-at-rest/
[35] https://elbywan.github.io/cryomongo/Mongo/Commands/SetParameter.html
[36] https://manpages.ubuntu.com/manpages/lunar/man3/mongoc_configuring_tls.3.html
[37] https://www.mongodb.com/docs/mongodb-shell/reference/configure-shell-settings-global/
[38] https://www.mongodb.com/docs/mongodb-shell/reference/options/
[39] https://stackoverflow.com/questions/40653112/starting-mongod-as-a-service-with-config-file-setting
[40] https://mongoing.com/docs/tutorial/monitor-with-snmp.html
[41] https://github.com/percona/percona-server-mongodb/blob/master/percona-packaging/conf/mongod.conf
[42] https://docs.percona.com/percona-server-for-mongodb/3.6/switch_storage_engines.html
[43] https://www.mongodb.com/docs/manual/reference/method/db.setProfilingLevel/
[44] https://dba.stackexchange.com/questions/95654/mongodb-3-0-configure-storage-engine-at-collection-or-database-level
[45] https://stackoverflow.com/questions/63210765/is-processmanagement-fork-to-true-needed-when-mongodb-is-only-application-runn
[46] https://gist.github.com/jwilm/5842956
[47] https://mongoing.com/docs/tutorial/configure-ssl.html
[48] https://www.ibm.com/docs/fr/product-master/12.0.0?topic=mongodb-enabling-authentication
[49] https://www.ibm.com/docs/en/product-master/12.0.0?topic=mongodb-enabling-authentication
[50] https://github.com/mongodb/docs/blob/master/source/reference/configuration-options.txt
[51] https://www.mongodb.com/docs/mongodb-shell/reference/configure-shell-settings/
[52] https://betterstack.com/community/guides/logging/database/how-to-start-logging-with-mongodb/
[53] https://stackoverflow.com/questions/56141687