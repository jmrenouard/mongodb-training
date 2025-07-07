# 📊 Tableau Complet des Paramètres WiredTiger MongoDB 8.0

Voici un tableau exhaustif des paramètres WiredTiger pour MongoDB 8.0, organisé par catégorie pour une référence complète.

## 💾 Paramètres de Cache et Mémoire

| Paramètre | Valeur par Défaut | Description | Configuration | Modification Runtime |
|-----------|------------------|-------------|---------------|---------------------|
| `cacheSizeGB` | 50% RAM - 1GB (min 256MB) | Taille du cache WiredTiger en GB | `storage.wiredTiger.engineConfig.cacheSizeGB: 4` | ✅ Via `wiredTigerEngineRuntimeConfig` |
| `cache_size` | Calculé automatiquement | Taille cache en string format | `configString: "cache_size=4G"` | ✅ Via `wiredTigerEngineRuntimeConfig` |
| `inMemorySizeGB` | - | Taille cache moteur in-memory | `storage.inMemory.engineConfig.inMemorySizeGB: 8` | ❌ |

## 🗜️ Paramètres de Compression

| Paramètre | Valeur par Défaut | Options | Description | Configuration |
|-----------|------------------|---------|-------------|---------------|
| `blockCompressor` | `snappy` | `snappy`, `zlib`, `zstd`, `none` | Compression des collections | `storage.wiredTiger.collectionConfig.blockCompressor: zstd` |
| `journalCompressor` | `snappy` | `snappy`, `zlib`, `zstd`, `none` | Compression du journal | `storage.wiredTiger.engineConfig.journalCompressor: zstd` |
| `prefixCompression` | `true` | `true`, `false` | Compression préfixe des index | `storage.wiredTiger.indexConfig.prefixCompression: true` |

## 🔄 Paramètres d'Éviction du Cache

| Paramètre | Valeur par Défaut | Plage | Description | Configuration Runtime |
|-----------|------------------|-------|-------------|----------------------|
| `eviction_trigger` | 95% | 80-99% | Seuil déclenchement éviction | `wiredTigerEngineRuntimeConfig: "eviction_trigger=90"` |
| `eviction_target` | 80% | 50-95% | Cible d'éviction | `wiredTigerEngineRuntimeConfig: "eviction_target=75"` |
| `eviction_dirty_trigger` | 5% | 1-50% | Seuil pages sales | `wiredTigerEngineRuntimeConfig: "eviction_dirty_trigger=10"` |
| `eviction_dirty_target` | 1% | 0.1-20% | Cible pages sales | `wiredTigerEngineRuntimeConfig: "eviction_dirty_target=2"` |
| `eviction_checkpoint_target` | 1% | 0.1-50% | Éviction lors checkpoints | `wiredTigerEngineRuntimeConfig: "eviction_checkpoint_target=5"` |
| `threads_min` | 1 | 1-20 | Nombre min threads éviction | `wiredTigerEngineRuntimeConfig: "eviction=(threads_min=2)"` |
| `threads_max` | 4 | 1-20 | Nombre max threads éviction | `wiredTigerEngineRuntimeConfig: "eviction=(threads_max=8)"` |

## 📝 Paramètres de Journalisation et Checkpoints

| Paramètre | Valeur par Défaut | Description | Configuration | Modification |
|-----------|------------------|-------------|---------------|-------------|
| `journal.enabled` | `true` | Activation du journal | `storage.journal.enabled: true` | ❌ |
| `journal.commitIntervalMs` | 100 | Intervalle commit (ms) | `storage.journal.commitIntervalMs: 50` | ✅ |
| `checkpoint.wait` | 60 | Intervalle checkpoint (sec) | Paramètre WiredTiger natif | ❌ |
| `checkpoint.log_size` | 2GB | Taille trigger checkpoint | Paramètre WiredTiger natif | ❌ |

## 🔢 Paramètres de Concurrence

| Paramètre | Valeur par Défaut | Plage | Description | Configuration |
|-----------|------------------|-------|-------------|---------------|
| `storageEngineConcurrentReadTransactions` | 128 | 64-256 | Tickets lecture simultanés | `setParameter.storageEngineConcurrentReadTransactions: 256` |
| `storageEngineConcurrentWriteTransactions` | 128 | 64-256 | Tickets écriture simultanés | `setParameter.storageEngineConcurrentWriteTransactions: 256` |
| `session_max` | 20000 | 1000-100000 | Sessions maximum | Paramètre WiredTiger natif | 

## 📊 Paramètres de Monitoring

| Paramètre | Valeur par Défaut | Description | Configuration |
|-----------|------------------|-------------|---------------|
| `statisticsLogDelaySecs` | 0 (désactivé) | Fréquence logs stats (sec) | `storage.wiredTiger.engineConfig.statisticsLogDelaySecs: 30` |
| `statistics` | `none` | Collecte statistiques | `configString: "statistics=(fast)"` |
| `verbose` | `[]` | Niveau verbosité | `configString: "verbose=[evictserver,checkpoint]"` |

## 🕒 Paramètres de Snapshot et Historique

| Paramètre | Valeur par Défaut | Plage | Description | Configuration |
|-----------|------------------|-------|-------------|---------------|
| `minSnapshotHistoryWindowInSeconds` | 300 | 0-600 | Fenêtre historique snapshots | `setParameter.minSnapshotHistoryWindowInSeconds: 600` |
| `maxConcurrentTransactions` | 1000000 | 1-10000000 | Transactions simultanées max | Paramètre WiredTiger natif |

## 📁 Paramètres d'Organisation

| Paramètre | Valeur par Défaut | Description | Configuration |
|-----------|------------------|-------------|---------------|
| `directoryForIndexes` | `false` | Index dans répertoires séparés | `storage.wiredTiger.engineConfig.directoryForIndexes: true` |
| `directoryPerDB` | `false` | DB dans répertoires séparés | `storage.directoryPerDB: true` |

## ⚙️ Paramètres Avancés de Configuration

| Paramètre | Valeur par Défaut | Description | Configuration |
|-----------|------------------|-------------|---------------|
| `configString` | - | Configuration WiredTiger native | `storage.wiredTiger.engineConfig.configString: "cache_size=4G"` |
| `wiredTigerEngineRuntimeConfig` | - | Configuration runtime | `setParameter.wiredTigerEngineRuntimeConfig: "cache_size=8G"` |
| `file_manager` | `close_idle_time=100000` | Gestionnaire fichiers | Configuration WiredTiger native |
| `checkpoint_sync` | `true` | Synchronisation checkpoints | Configuration WiredTiger native |

## 🔍 Paramètres de Debugging

| Paramètre | Valeur par Défaut | Description | Configuration |
|-----------|------------------|-------------|---------------|
| `debug_mode` | - | Mode debug | `configString: "debug_mode=(eviction,checkpoint)"` |
| `error_prefix` | - | Préfixe erreurs | `configString: "error_prefix=MongoDB"` |
| `log` | - | Configuration logs | `configString: "log=(enabled,archive,path=journal)"` |

## 💻 Exemples de Configuration Pratique

### Configuration Fichier YAML
```yaml
storage:
  dbPath: "/data/db"
  engine: wiredTiger
  directoryPerDB: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 8
      directoryForIndexes: true
      statisticsLogDelaySecs: 300
      journalCompressor: zstd
      configString: "eviction=(threads_min=4,threads_max=8)"
    collectionConfig:
      blockCompressor: zstd
    indexConfig:
      prefixCompression: true
```

### Configuration Runtime
```javascript
// Modification du cache
db.adminCommand({
  "setParameter": 1,
  "wiredTigerEngineRuntimeConfig": "cache_size=16G"
})

// Configuration éviction
db.adminCommand({
  "setParameter": 1,
  "wiredTigerEngineRuntimeConfig": "eviction=(threads_min=6,threads_max=12)"
})

// Paramètres de concurrence
db.adminCommand({
  "setParameter": 1,
  "storageEngineConcurrentWriteTransactions": 256
})
```

### Vérification des Paramètres
```javascript
// Vérifier la configuration actuelle
db.serverStatus().storageEngine
db.serverStatus().wiredTiger.cache["maximum bytes configured"]

// Paramètres spécifiques
db.adminCommand({getParameter: 1, wiredTigerEngineRuntimeConfig: 1})
db.adminCommand({getParameter: 1, minSnapshotHistoryWindowInSeconds: 1})
```

## ⚠️ Points de Vigilance

### **Configuration du Cache**
- Ne jamais dépasser 80% de la RAM disponible pour `cacheSizeGB`[1][2]
- Laisser suffisamment de mémoire pour le système d'exploitation
- Surveiller le ratio `cache_used/cache_configured`

### **Éviction**
- Un mauvais réglage peut causer des ralentissements importants[3][4]
- Surveiller les métriques d'éviction dans `db.serverStatus().wiredTiger.cache`
- Adapter `threads_max` selon la charge de travail

### **Compression**
- `zstd` offre le meilleur ratio mais consomme plus de CPU[5][6]
- `snappy` reste le meilleur équilibre performance/compression
- Éviter `none` sauf cas spécifiques

### **Concurrence**
- Les paramètres de tickets sont dynamiques depuis MongoDB 7.0[1][7]
- Ne pas dépasser 256 tickets sans monitoring approprié
- Surveiller les métriques `qr`/`qw` et `ar`/`aw`

### **Checkpoints**
- Intervalles trop courts peuvent impacter les performances[8][9]
- Surveiller la durée des checkpoints dans les logs
- Adapter selon la charge d'écriture

### **Paramètres Runtime**
- Les modifications via `wiredTigerEngineRuntimeConfig` ne persistent pas après redémarrage[10][11]
- Toujours documenter les changements temporaires
- Prévoir des scripts de configuration automatique

Ce tableau constitue une référence complète pour optimiser WiredTiger selon vos besoins spécifiques. Chaque paramètre doit être ajusté en fonction de votre charge de travail et de vos ressources système.

[1] https://www.mongodb.com/docs/manual/core/wiredtiger/
[2] https://www.dragonflydb.io/faq/mongodb-wiredtiger-memory-limit
[3] https://muralidba.blogspot.com/2018/03/wiredtiger-eviction-thresholds.html
[4] https://muralidba.blogspot.com/2018/03/how-does-wiredtiger-cache-eviction.html
[5] https://www.alibabacloud.com/help/doc-detail/2879251.html
[6] https://infohub.delltechnologies.com/en-us/l/dell-powerstore-mongodb-solution-guide/wiredtiger-storage-engine-2/
[7] https://www.mongodb.com/docs/v7.0/core/wiredtiger/
[8] https://www.percona.com/blog/tuning-mongodb-for-bulk-loads/
[9] http://source.wiredtiger.com/mongodb-5.0/checkpoint.html
[10] https://www.mongodb.com/community/forums/t/wiredtiger-cachesize-setting-not-persistent-across-restart/206333
[11] https://stackoverflow.com/questions/78673051/config-eviction-for-mongodb-in-docker-compose
[12] https://mongoing.com/docs/core/wiredtiger.html
[13] https://www.mongodb.com/docs/manual/tutorial/change-replica-set-wiredtiger/
[14] https://www.mongodb.com/docs/manual/tutorial/change-standalone-wiredtiger/
[15] https://source.wiredtiger.com/mongodb-3.4/architecture.html
[16] https://www.mongodb.com/docs/manual/reference/parameters/
[17] https://github.com/mongodb/mongo/blob/master/src/mongo/db/storage/wiredtiger/README.md?plain=1
[18] https://www.mongodb.com/docs/manual/reference/configuration-options/
[19] https://www.mongodb.com/docs/manual/administration/production-checklist-operations/
[20] https://docs.percona.com/percona-server-for-mongodb/8.0/inmemory.html
[21] https://source.wiredtiger.com/mongodb-3.2/config_strings.html
[22] https://docs.byteplus.com/en/docs/mongodb/supported-parameter
[23] https://stackoverflow.com/questions/32355875/mongodb-wiredtiger-configuration
[24] https://www.percona.com/blog/mongodb-101-how-to-tune-your-mongodb-configuration-after-upgrading-to-more-memory/
[25] https://www.mongodb.com/docs/ops-manager/current/reference/deployment-advanced-options/
[26] https://support.servbay.com/advanced-settings/modify-configurations/modify-mongodb-settings
[27] https://source.wiredtiger.com/mongodb-3.4/database_config.html
[28] https://www.mongodb.com/ko-kr/docs/v6.3/core/wiredtiger/
[29] https://docs.huihoo.com/mongodb/3.2/core/wiredtiger.html
[30] https://source.wiredtiger.com/mongodb-6.0/eviction.html
[31] https://source.wiredtiger.com/develop/arch-checkpoint.html
[32] https://developers.redhat.com/blog/2018/09/17/configuring-the-mongodb-wiredtiger-memory-cache-for-rhmap
[33] https://source.wiredtiger.com/develop/eviction.html
[34] https://serverfault.com/questions/732692/enabling-wiredtiger-engine-in-mongodb-3
[35] https://www.cnblogs.com/xibuhaohao/p/12313310.html
[36] https://minervadb.xyz/mongodb-checkpointing/
[37] https://source.wiredtiger.com/mongodb-3.4/tune_cache.html
[38] https://docs.percona.com/percona-monitoring-and-management/3/reference/dashboards/dashboard-mongodb-wiredtiger-details.html
[39] https://www.linkedin.com/pulse/wiredtiger-mongodb-developers-guide-raja-r-azddc
[40] https://www.solarwinds.com/blog/deciding-which-storage-engine-is-right-for-you-wiredtiger
[41] https://www.mongodb.com/docs/manual/administration/production-notes/
[42] http://learnmongodbthehardway.com/schema/wiredtiger/
[43] https://www.mongodb.com/docs/manual/reference/program/mongod/
[44] https://source.wiredtiger.com/mongodb-4.2/config_strings_lang_java.html
[45] http://www.mongodb.com/docs/v7.0/core/wiredtiger/
[46] https://amperecomputing.com/tuning-guides/mongoDB-tuning-guide
[47] http://source.wiredtiger.com/mongodb-5.0/database_config.html
[48] http://source.wiredtiger.com/pdfs/WiredTiger-1page.pdf