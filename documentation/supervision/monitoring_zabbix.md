# Sondes MongoDB de Zabbix

## Définition

Les sondes MongoDB de Zabbix sont des éléments de surveillance intégrés au plugin MongoDB de Zabbix Agent 2, permettant de collecter automatiquement des métriques et statistiques complètes sur les instances MongoDB[1][2]. Ces sondes utilisent le plugin MongoDB natif pour effectuer une collecte de données en masse, récupérant la plupart des métriques en une seule requête grâce à la fonctionnalité de collecte groupée de Zabbix[1][3].

## Architecture et Fonctionnement

### 🔧 Plugin MongoDB Zabbix Agent 2

Le plugin MongoDB est un plugin chargeable disponible depuis Zabbix 5.0, entièrement intégré à partir de la version 6.0.6[2][4]. Il fonctionne directement avec Zabbix Agent 2 sans nécessiter de scripts externes ou de packages additionnels[1][5].

### ⚙️ Paramètres de Configuration Principaux

Le plugin MongoDB utilise un fichier de configuration `mongo.conf` avec plusieurs paramètres essentiels[2][4] :

| Paramètre | Obligatoire | Plage | Défaut | Description |
|-----------|-------------|-------|---------|-------------|
| `Plugins.MongoDB.Default.Uri` | Non | - | - | URI par défaut pour la connexion MongoDB (format : `tcp://127.0.0.1:27017`) |
| `Plugins.MongoDB.Default.User` | Non | - | - | Nom d'utilisateur par défaut pour MongoDB |
| `Plugins.MongoDB.Default.Password` | Non | - | - | Mot de passe par défaut pour MongoDB |
| `Plugins.MongoDB.KeepAlive` | Non | 60-900 | 300 | Temps d'attente maximum avant fermeture des connexions inutilisées |
| `Plugins.MongoDB.Timeout` | Non | 1-30 | timeout global | Délai d'exécution des requêtes |

### 🔐 Sessions Nommées

Le plugin supporte les sessions nommées permettant de surveiller plusieurs instances MongoDB depuis un seul agent[2][4] :

```ini
Plugins.MongoDB.Sessions.<SessionName>.Uri
Plugins.MongoDB.Sessions.<SessionName>.User
Plugins.MongoDB.Sessions.<SessionName>.Password
```

## 📊 Sondes et Métriques Collectées

### Sondes de Connectivité et État

#### `mongodb.ping`
- **Description** : Teste la connectivité avec l'instance MongoDB[6][7]
- **Valeur de retour** : 1 (connexion active) / 0 (connexion fermée)
- **Paramètres** : `[connString, user, password]`

#### `mongodb.version` 
- **Description** : Retourne la version du serveur MongoDB[6][7]
- **Valeur de retour** : Chaîne de caractères
- **Paramètres** : `[connString, user, password]`

### Sondes de Performance du Serveur

#### `mongodb.server.status`
- **Description** : Retourne l'état complet de la base de données[6][7]
- **Valeur de retour** : Objet JSON avec toutes les métriques serveur
- **Paramètres** : `[connString, user, password]`

#### `mongodb.connpool.stats`
- **Description** : Informations sur les connexions sortantes vers les membres du cluster ou replica set[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password]`

### Sondes de Base de Données

#### `mongodb.db.stats`
- **Description** : Statistiques reflétant l'état d'une base de données spécifique[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password, database]`

#### `mongodb.db.discovery`
- **Description** : Liste des bases de données découvertes (utilisé pour la découverte automatique)[6][7]
- **Valeur de retour** : Objet JSON au format LLD
- **Paramètres** : `[connString, user, password]`

### Sondes de Collections

#### `mongodb.collection.stats`
- **Description** : Statistiques de stockage détaillées pour une collection donnée[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password, database, collection]`

#### `mongodb.collections.discovery`
- **Description** : Liste des collections découvertes pour la découverte automatique[6][7]
- **Valeur de retour** : Objet JSON au format LLD
- **Paramètres** : `[connString, user, password]`

#### `mongodb.collections.usage`
- **Description** : Statistiques d'utilisation pour les collections[6][7]  
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password]`

### Sondes de Réplication

#### `mongodb.rs.status`
- **Description** : État du replica set depuis le point de vue du membre où la méthode est exécutée[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password]`

#### `mongodb.rs.config`
- **Description** : Configuration actuelle du replica set[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password]`

#### `mongodb.oplog.stats`
- **Description** : État du replica set utilisant les données de l'oplog[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password]`

### Sondes de Sharding

#### `mongodb.sh.discovery`
- **Description** : Liste des shards découverts dans le cluster[6][7]
- **Valeur de retour** : Objet JSON au format LLD  
- **Paramètres** : `[connString, user, password]`

#### `mongodb.jumbo_chunks.count`
- **Description** : Nombre de chunks jumbo dans le cluster[6][7]
- **Valeur de retour** : Objet JSON
- **Paramètres** : `[connString, user, password]`

## 📈 Templates et Configuration

### Templates Disponibles

Zabbix propose deux templates principaux pour MongoDB[1][5][8] :

1. **"MongoDB node by Zabbix agent 2"** : Pour surveiller un serveur MongoDB unique
2. **"MongoDB cluster by Zabbix Agent 2"** : Pour surveiller un cluster MongoDB complet

### 🔧 Macros de Configuration Essentielles

| Macro | Description | Valeur par défaut |
|-------|-------------|-------------------|
| `{$MONGODB.CONNSTRING}` | Chaîne de connexion MongoDB | `tcp://localhost:27017` |
| `{$MONGODB.USER}` | Nom d'utilisateur MongoDB | - |
| `{$MONGODB.PASSWORD}` | Mot de passe MongoDB | - |
| `{$MONGODB.CONNS.PCT.USED.MAX.WARN}` | Pourcentage maximum de connexions utilisées | 80 |
| `{$MONGODB.CURSOR.TIMEOUT.MAX.WARN}` | Nombre maximum de curseurs expirés par seconde | 1 |
| `{$MONGODB.CURSOR.OPEN.MAX.WARN}` | Nombre maximum de curseurs ouverts | - |

### 🔍 Macros de Filtrage pour la Découverte

| Macro | Fonction |
|-------|----------|
| `{$MONGODB.LLD.FILTER.DB.MATCHES}` | Bases de données à découvrir (regex) |
| `{$MONGODB.LLD.FILTER.DB.NOT_MATCHES}` | Bases de données à exclure |
| `{$MONGODB.LLD.FILTER.COLLECTION.MATCHES}` | Collections à découvrir |
| `{$MONGODB.LLD.FILTER.COLLECTION.NOT_MATCHES}` | Collections à exclure |

## 💻 Commandes de Test et Validation

### Test de Connectivité
```bash
zabbix_get -s mongodb.node -k 'mongodb.ping["{$MONGODB.CONNSTRING}","{$MONGODB.USER}","{$MONGODB.PASSWORD}"]'
```

### Exemples de Clés d'Éléments
```bash
# Test de connexion
mongodb.ping["tcp://localhost:27017","zbx_monitor","password"]

# Statistiques serveur  
mongodb.server.status["tcp://localhost:27017","zbx_monitor","password"]

# Statistiques de collection spécifique
mongodb.collection.stats["tcp://localhost:27017","zbx_monitor","password","mydb","mycollection"]
```

## ✅ Avantages

- **Surveillance Native** : Intégration complète sans scripts externes[1][5]
- **Collecte Groupée** : Récupération de multiples métriques en une seule requête[1][3]
- **Découverte Automatique** : Détection automatique des bases de données, collections et shards[1][8]
- **Support TLS** : Connexions sécurisées avec authentification par certificats[2][4]
- **Sessions Multiples** : Surveillance de plusieurs instances MongoDB depuis un agent[2][4]
- **Templates Prêts** : Templates préconfigurés pour nœuds et clusters[1][5][8]

## ❌ Inconvénients

- **Version Zabbix** : Nécessite Zabbix 5.0+ (recommandé 6.0+)[1][2][4]
- **Agent 2 Obligatoire** : Ne fonctionne qu'avec Zabbix Agent 2[1][5]
- **Performances Discovery** : Les opérations de découverte peuvent être coûteuses avec de nombreuses DB/collections[1][3]
- **Configuration Initiale** : Requiert une configuration spécifique du plugin et des macros[2][8]

## ⚠️ Points de Vigilance

**Sécurité des Connexions** : L'utilisation de mots de passe en clair dans les macros présente un risque de vol d'identifiants. Il est recommandé d'utiliser des sessions nommées avec authentification par certificats TLS[2][4].

**Performance de Découverte** : La découverte automatique peut impacter les performances MongoDB avec un grand nombre de bases de données ou collections. Utilisez les macros de filtrage pour limiter la portée[1][3].

**Authentification MongoDB** : Vérifiez que l'utilisateur MongoDB dispose des privilèges suffisants (lecture sur les bases de données système pour les métriques serveur)[5][8].

**Continuité de Service** : Une mauvaise configuration des connexions peut causer des interruptions de surveillance. Testez toujours la connectivité avant la mise en production[9][10].

[1] https://www.zabbix.com/integrations/mongodb
[2] https://www.zabbix.com/documentation/current/en/manual/appendix/config/zabbix_agent2_plugins/mongodb_plugin
[3] https://www.zabbix.com/fr/integrations/mongodb
[4] https://www.zabbix.com/documentation/6.0/en/manual/appendix/config/zabbix_agent2_plugins/mongodb_plugin
[5] https://blog.zabbix.com/monitoring-mongodb-nodes-and-clusters-with-zabbix/16031/
[6] https://www.bookstack.cn/read/zabbix-6.0-en/04005d55cd7ce98f.md
[7] https://www.mongodb.com/docs/manual/reference/method/db.collection.latencyStats/
[8] https://noise.getoto.net/2021/10/05/monitoring-mongodb-nodes-and-clusters-with-zabbix/
[9] https://stackoverflow.com/questions/68906631/how-to-mongodb-monitoring-with-zabbix
[10] https://www.zabbix.com/documentation/current/en/manual/config/items/itemtypes/dependent_items
[11] https://www.youtube.com/watch?v=youlo-8t91U
[12] https://github.com/nightw/mikoomi-zabbix-mongodb-monitoring
[13] https://github.com/omni-lchen/zabbix-mongodb
[14] https://n8n.io/integrations/mongodb/and/zabbix/
[15] https://www.zabbix.com/documentation/6.4/fr/manual/appendix/config/zabbix_agent2_plugins/mongodb_plugin
[16] https://github.com/petrushinvs/mongodb-zabbix-templates
[17] https://www.zabbix.com/documentation/6.4/fr/manual/config/templates_out_of_the_box/zabbix_agent2
[18] https://www.zabbix.com/documentation/6.0/fr/manual/appendix/config/zabbix_agent2_plugins/mongodb_plugin
[19] https://www.zabbix.com/documentation/5.0/fr/manual/config/templates_out_of_the_box/zabbix_agent2
[20] https://www.zabbix.com/documentation/current/en/manual/config/items
[21] https://support.zabbix.com/si/jira.issueviews:issue-html/ZBX-24230/ZBX-24230.html
[22] https://www.zabbix.com/documentation/current/en/manual/config/items/itemtypes/calculated
[23] https://www.zabbix.com/documentation/6.4/fr/manual/appendix/items/encoding_of_values
[24] https://www.zabbix.com/documentation/6.4/fr/manual/web_interface/frontend_sections/data_collection/hosts/items
[25] https://www.zabbix.com/documentation/6.4/fr/manual/web_interface/frontend_sections/data_collection/templates
[26] https://www.zabbix.com/forum/zabbix-troubleshooting-and-problems/447226-mongodb-unknown-metrics
[27] https://www.zabbix.com/documentation/6.0/ua/manual/config/items/itemtypes/zabbix_agent/zabbix_agent2
[28] https://www.zabbix.com/documentation/current/en/manual/config/items/item
[29] https://mongoing.com/docs/reference/method/db.collection.stats.html
[30] https://www.zabbix.com/documentation/current/en/manual/config/items/itemtypes/zabbix_agent/zabbix_agent2
[31] https://www.zabbix.com/documentation/5.4/en/manual/config/items/itemtypes/zabbix_agent/zabbix_agent2
[32] https://signoz.io/blog/mongodb-monitoring-tools/
[33] https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/db/mongodb
[34] https://github.com/dastra/zabbix-mongodb/blob/master/README.md
[35] https://git.zabbix.com/projects/AP/repos/mongodb/browse
[36] https://gitee.com/cosmozhu/mongodb-zabbix-templates-4.0
[37] https://www.zabbix.com/documentation/6.0/fr/manual/config/items/itemtypes/internal
[38] https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/db/mongodb_cluster
[39] https://www.mongodb.com/community/forums/t/how-to-monitor-mongodb-replicat-set-3-nodes-with-zabbix/271261
[40] https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/db/mongodb_cluster/README.md?at=refs%2Fheads%2Frelease%2F5.0
[41] https://www.zabbix.com/documentation/6.4/fr/manual/config/items/itemtypes/script
[42] https://www.zabbix.com/documentation/6.0/fr/manual/config/items/item/key
[43] https://www.zabbix.com/documentation/6.0/en/manual/config/items/itemtypes/zabbix_agent/zabbix_agent2