Voici une procédure complète pour vérifier l’état d’un serveur MongoDB, identifier les paramètres clés à surveiller, les commandes à utiliser et les pistes de correction en cas d’anomalie.

## 🛠️ Points de contrôle principaux

- **Disponibilité du service**
- **Nombre de connexions**
- **Utilisation mémoire**
- **Charge CPU**
- **Utilisation disque et I/O**
- **Performances des requêtes**
- **État de la réplication (le cas échéant)**
- **Performances du réseau**

## 🛠️ Commandes de vérification et outils

### 1. Disponibilité du service

**Commande système (Linux) :**
```bash
systemctl status mongod
```
ou
```bash
systemctl is-active mongod
```
Permet de vérifier si le service MongoDB est actif ou non[1].

### 2. État du serveur MongoDB

**Dans le shell MongoDB :**
```javascript
db.serverStatus()
```
Affiche un ensemble complet d’informations sur l’état du serveur, dont :
- **uptime** : temps de fonctionnement
- **connections.current** : nombre de connexions actives
- **mem** : utilisation mémoire
- **cpu** : utilisation CPU
- **network** : trafic réseau
- **locks** : contention de verrous
- **asserts** : erreurs et assertions[2][3][4]

### 3. Nombre de connexions

**Dans le shell MongoDB :**
```javascript
db.serverStatus().connections
```
ou
```javascript
db.runCommand({serverStatus: 1}).connections
```
Affiche le nombre de connexions actives et disponibles[2][3][5].

### 4. Utilisation mémoire

**Dans le shell MongoDB :**
```javascript
db.serverStatus().mem
```
Indique l’utilisation mémoire (résident, virtuelle, mappée)[2][3][6].

**Paramètre clé :**
- **storage.wiredTiger.engineConfig.cacheSizeGB** : taille du cache WiredTiger (par défaut, 50% de la RAM disponible, max 1GB sur certains systèmes)[7][6].

### 5. Charge CPU

**Sur le serveur :**
```bash
top
```
ou
```bash
htop
```
ou via MongoDB :
```javascript
db.serverStatus().cpu
```
Affiche l’utilisation CPU du système et de MongoDB[2][5][8].

### 6. Utilisation disque et I/O

**Sur le serveur :**
```bash
df -h
```
pour l’espace disque.

```bash
iostat -x 1
```
pour les performances I/O.

**Dans MongoDB :**
```javascript
db.serverStatus().storageEngine
```
Affiche les statistiques du moteur de stockage[2][3][9].

**Commandes spécifiques :**
```javascript
db.stats()
db.collection.stats()
```
pour des statistiques par base ou par collection[4].

### 7. Performances des requêtes

**Dans le shell MongoDB :**
```javascript
db.currentOp()
```
Affiche les opérations en cours et leur statut[8][10].

```javascript
db.collection.find(...).explain("executionStats")
```
Analyse l’exécution d’une requête et l’utilisation des index[11][10].

**Utilisation de mongostat et mongotop :**
```bash
mongostat
mongotop
```
Donne un aperçu en temps réel des opérations et du temps passé en lecture/écriture[12][13][4].

### 8. État de la réplication

**Dans le shell MongoDB :**
```javascript
rs.status()
```
Affiche l’état de la réplication (membres, primaire, secondaire, lag, etc.)[2][4].

### 9. Performances réseau

**Dans le shell MongoDB :**
```javascript
db.serverStatus().network
```
Affiche le trafic réseau entrant/sortant[2][3].

## 📊 Tableau récapitulatif des points de contrôle

| Point de contrôle         | Commande/outil principal         | Paramètre clé/Métrique            |
|--------------------------|----------------------------------|-----------------------------------|
| Disponibilité            | systemctl status mongod          | actif/inactif                     |
| Nombre de connexions     | db.serverStatus().connections    | connections.current               |
| Utilisation mémoire      | db.serverStatus().mem            | mem.resident, mem.virtual         |
| Charge CPU               | db.serverStatus().cpu, top       | cpu.usage, cpu.system             |
| Utilisation disque/I/O   | df -h, iostat, db.stats()        | storageEngine, disk usage         |
| Performances requêtes    | db.currentOp(), explain()        | executionStats, query time        |
| État réplication         | rs.status()                      | members, lag                      |
| Performances réseau      | db.serverStatus().network        | network.bytesIn, network.bytesOut |

## 🚨 Points de vigilance

- **Nombre élevé de connexions** : peut saturer le serveur. Vérifiez le paramètre `net.maxIncomingConnections` et limitez les connexions inutiles[7][5].
- **Utilisation mémoire excessive** : ajustez `storage.wiredTiger.engineConfig.cacheSizeGB` selon la RAM disponible[7][6].
- **Charge CPU élevée** : vérifiez les requêtes longues avec `db.currentOp()` et optimisez les index[14][8][10].
- **Contention disque/I/O** : surveillez l’espace disque, utilisez des SSD, séparez les logs et les données[9].
- **Réplication lag** : surveillez avec `rs.status()`, vérifiez la santé des secondaires[2][4].
- **Risque de saturation réseau** : surveillez le trafic avec `db.serverStatus().network`[2][3].

## 🔧 Pistes de correction

- **Optimiser les requêtes** : utiliser `explain()` pour détecter les scans complets, créer des index appropriés[14][11][10].
- **Limiter les connexions** : ajuster `net.maxIncomingConnections` et fermer les connexions inactives[7][5].
- **Ajuster la mémoire** : réduire ou augmenter le cache WiredTiger selon les ressources disponibles[7][6].
- **Surveiller l’espace disque** : libérer de l’espace si nécessaire, utiliser des SSD pour les bases à forte activité[9].
- **Gérer la réplication** : vérifier la santé des membres, résoudre les problèmes de lag[2][4].
- **Surveiller et alerter** : utiliser des outils de monitoring (Prometheus, Grafana, Atlas) pour détecter les anomalies rapidement[15][4][5].

## 💻 Exemples de commandes pratiques

```bash
# Vérification du service
systemctl status mongod

# Nombre de connexions
mongo --eval "printjson(db.serverStatus().connections)"

# Utilisation mémoire
mongo --eval "printjson(db.serverStatus().mem)"

# Opérations en cours
mongo --eval "db.currentOp()"

# Analyse d'une requête
mongo --eval "db.collection.find({field: 'value'}).explain('executionStats')"

# État de la réplication
mongo --eval "rs.status()"

# Utilisation disque
df -h
iostat -x 1
```

## ✅ Avantages d’une procédure complète

- **Détection rapide des problèmes** : surveillance proactive des métriques clés.
- **Optimisation des performances** : ajustement des paramètres selon l’usage.
- **Prévention des pannes** : identification des signaux faibles avant qu’ils ne dégénèrent.

## ❌ Inconvénients

- **Complexité** : nécessite une bonne connaissance de MongoDB et de l’OS.
- **Surveillance continue** : implique la mise en place d’outils de monitoring pour une réactivité optimale.

Cette procédure vous permettra de maintenir un serveur MongoDB sain, performant et disponible.

[1] https://www.cisco.com/c/fr_ca/support/docs/security/securex/218338-repair-mongodb-after-an-unclean-shutdown.html
[2] https://www.datasunrise.com/knowledge-center/mongodb-monitoring/
[3] https://virtual-dba.com/blog/mongodb-serverstatus-health-check-tips/
[4] https://sematext.com/blog/mongodb-monitoring-tools/
[5] https://docs.percona.com/percona-monitoring-and-management/3/reference/dashboards/dashboard-mongodb-router-summary.html
[6] https://www.dragonflydb.io/faq/mongodb-reduce-memory-usage
[7] https://www.percona.com/blog/mongodb-101-5-configuration-options-that-impact-performance-and-how-to-set-them/
[8] https://docs.byteplus.com/en/docs/mongodb/troubleshooting-for-high-cpu-utilization
[9] https://shiviyer.hashnode.dev/enhance-mongodb-efficiency-troubleshoot-io-overload-and-implement-best-practices
[10] https://www.dragonflydb.io/faq/mongodb-performance-troubleshooting
[11] https://javanexus.com/blog/overcoming-mongodb-performance-issues-scaling-apps
[12] https://www.digitalocean.com/community/tutorials/how-to-monitor-mongodb-s-performance
[13] https://signoz.io/blog/mongodb-monitoring/
[14] https://accuweb.cloud/blog/fixing-mongodb-performance-issues
[15] https://logz.io/blog/mongodb-monitoring-prometheus-best-practices/
[16] https://www.mongodb.com/community/forums/t/get-the-status-of-cpu-ram-disk-util-from-mongodb-atlas/193430
[17] https://www.ibm.com/docs/fr/db2/11.1.0?topic=sources-testing-network-connection-mongodb-rest-service-server
[18] https://www.mongodb.com/docs/manual/reference/command/serverStatus/
[19] https://www.servicenow.com/docs/fr-FR/bundle/vancouver-it-operations-management/page/product/agent-client-collector/reference/mongodb-checks-policies.html
[20] https://www.ibm.com/docs/fr/spp/10.1.16?topic=server-testing-mongodb-connection
[21] https://www.mongodb.com/community/forums/t/how-to-analyze-mongodb-ram-usage/12108
[22] https://www.mongodb.com/resources/products/capabilities/how-to-monitor-mongodb-and-what-metrics-to-monitor
[23] https://sematext.com/blog/mongodb-monitoring/
[24] https://www.mongodb.com/resources/products/capabilities/performance-best-practices
[25] https://www.mongodb.com/docs/manual/administration/analyzing-mongodb-performance/
[26] https://www.mongodb.com/developer/products/mongodb/guide-to-optimizing-mongodb-performance/
[27] https://geekflare.com/fr/mongodb-queries-examples/
[28] https://mongoing.com/docs/reference/program/mongotop.html
[29] https://www.mongodb.com/community/forums/t/finding-mongodb-cpu-usage-disk-utilization-ram-using-query-command/193420