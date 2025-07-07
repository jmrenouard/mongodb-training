# Gestion des Opérations Courantes : currentOp & killOp

## Définition : Surveillance et Contrôle des Opérations

MongoDB propose des outils puissants pour surveiller et contrôler les opérations en cours d'exécution sur une instance. Ces mécanismes permettent d'identifier les requêtes problématiques et d'intervenir si nécessaire pour préserver les performances du système[1][2].

## 📊 Surveillance des Opérations avec currentOp

### Méthodes Disponibles

MongoDB offre plusieurs approches pour surveiller les opérations courantes :

| Méthode | Description | Limitations |
|---------|-------------|-------------|
| `db.currentOp()` | Méthode helper shell | Limite de 16MB BSON[3] |
| `currentOp` | Commande base de données | Limite de 16MB BSON[4] |
| `$currentOp` | Pipeline d'agrégation | Recommandé, pas de limite[1][5] |

### 💻 Utilisation de base

```javascript
// Afficher toutes les opérations actives
db.currentOp(true)

// Afficher uniquement ses propres opérations
db.currentOp({"$ownOps": true})

// Utilisation du pipeline d'agrégation (recommandé)
use admin
db.aggregate([
  { $currentOp: { allUsers: true } }
])
```

### ⚙️ Paramètres de Configuration

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `allUsers` | Boolean | Affiche les opérations de tous les utilisateurs | `false` |
| `idleConnections` | Boolean | Inclut les connexions inactives | `false` |
| `idleCursors` | Boolean | Inclut les curseurs inactifs | `false` |
| `idleSessions` | Boolean | Inclut les sessions inactives | `false` |
| `localOps` | Boolean | Opérations locales uniquement (clusters) | `false` |

### 💻 Exemples de Requêtes Ciblées

```javascript
// Opérations longues (> 3 secondes)
db.aggregate([
  { $currentOp: { allUsers: true } },
  { $match: { 
    "active": true, 
    "secs_running": { "$gt": 3 } 
  }}
])

// Opérations d'écriture en attente de verrou
db.aggregate([
  { $currentOp: { allUsers: true } },
  { $match: { 
    "waitingForLock": true,
    "$or": [
      { "op": { "$in": ["insert", "update", "remove"] } },
      { "query.findandmodify": { "$exists": true } }
    ]
  }}
])

// Opérations sur une base spécifique
db.aggregate([
  { $currentOp: { allUsers: true } },
  { $match: { 
    "active": true,
    "ns": /^mabase\./,
    "secs_running": { "$gt": 5 }
  }}
])
```

## 🔄 Terminaison des Opérations avec killOp

### Méthodes de Terminaison

| Méthode | Contexte | Usage |
|---------|----------|-------|
| `db.killOp(opid)` | Opération unique | Terminaison par ID d'opération |
| `killSessions` | Session complète | Terminaison de toutes les opérations d'une session |
| `killAllSessions` | Utilisateur | Terminaison de toutes les sessions d'un utilisateur |

### 💻 Utilisation de killOp

```javascript
// 1. Identifier l'opération
db.aggregate([
  { $currentOp: { allUsers: true } },
  { $match: { "secs_running": { "$gt": 10 } } }
])

// 2. Terminer l'opération
db.killOp(12345)  // Remplacer par l'opid réel

// Terminaison par session
db.runCommand({
  killSessions: [
    { "id": UUID("f9b3d8d9-9496-4fff-868f-04a6196fc58a") }
  ]
})
```

### ⚙️ Gestion des Clusters Shardés

Pour les environnements shardés, la gestion des opérations nécessite des précautions particulières :

```javascript
// Identification des opérations sur mongos
use admin
db.aggregate([
  { $currentOp: { allUsers: true, localOps: true } },
  { $match: { op: "getmore", "command.collection": "maCollection" } }
])

// Terminaison d'opérations multi-shard
db.killOp("shardA:12345")
db.killOp("shardB:67890")
```

## 📊 Informations Disponibles

### Champs Principaux

| Champ | Description |
|-------|-------------|
| `opid` | Identifiant unique de l'opération |
| `active` | Indique si l'opération est active |
| `secs_running` | Durée d'exécution en secondes |
| `microsecs_running` | Durée d'exécution en microsecondes |
| `op` | Type d'opération (query, insert, update, remove) |
| `ns` | Namespace (base.collection) |
| `desc` | Description de l'opération |
| `waitingForLock` | En attente d'un verrou |
| `numYields` | Nombre de fois où l'opération a cédé la priorité |

### 💻 Script de Monitoring Automatisé

```javascript
// Fonction pour tuer les opérations longues
function killLongRunningOps(maxSecsRunning) {
  const currOp = db.currentOp();
  currOp.inprog.forEach(function(op) {
    if (op.secs_running > maxSecsRunning && 
        op.op === "query" && 
        !op.ns.startsWith("local")) {
      print("Killing opId: " + op.opid + 
            " running for " + op.secs_running + " seconds");
      db.killOp(op.opid);
    }
  });
}

// Utilisation
killLongRunningOps(30);
```

## 🔐 Contrôle d'Accès et Privilèges

### Privilèges Requis

| Action | Privilège | Description |
|--------|-----------|-------------|
| `currentOp` | `inprog` | Voir les opérations en cours |
| `killOp` | `killop` | Terminer les opérations |
| `killSessions` | `killAnySession` | Terminer les sessions |

### 💻 Création de Rôle Personnalisé

```javascript
use admin
db.createRole({
  role: "operationMonitor",
  privileges: [
    { resource: { cluster: true }, actions: ["inprog", "killop"] }
  ],
  roles: []
})

// Attribution du rôle
db.grantRolesToUser("monUtilisateur", ["operationMonitor"])
```

## ✅ Avantages

- **Surveillance en temps réel** : Identification immédiate des opérations problématiques
- **Contrôle granulaire** : Terminaison sélective des opérations
- **Intégration pipeline** : Utilisation avec les outils d'agrégation MongoDB
- **Gestion des clusters** : Support complet des environnements shardés

## ❌ Inconvénients

- **Complexité clusters** : Gestion plus complexe en environnement shardé
- **Risque de corruption** : Terminaison inappropriée peut affecter la cohérence
- **Privilèges élevés** : Nécessite des droits administrateur
- **Impact performance** : Le monitoring lui-même consomme des ressources

## ⚠️ Points de Vigilance

**Sécurité des Terminaisons** : Ne jamais terminer les opérations internes de MongoDB (réplication, maintenance)[6][7]. Seules les opérations clients doivent être interrompues.

**Gestion des Transactions** : Les sessions avec des transactions en état "prepared" ne peuvent pas être terminées[8][9]. Cela peut laisser des verrous actifs.

**Propagation Cluster** : Dans un environnement shardé, certaines terminaisons ne se propagent pas automatiquement à tous les shards[6][10].

**Privilèges Restrictifs** : Le privilège `inprog` donne accès à toutes les opérations en cours, ce qui peut révéler des informations sensibles[11][12].

**Monitoring Continu** : Les opérations terminées peuvent réapparaître dans les listes de sessions courantes jusqu'à leur nettoyage complet[8][13].

[1] https://www.mongodb.com/docs/manual/reference/operator/aggregation/currentOp/
[2] https://stackoverflow.com/questions/32315332/strange-about-results-of-db-currentop-inprog
[3] https://www.mongodb.com/docs/manual/reference/method/db.currentOp/
[4] https://www.bookstack.cn/read/mongodb-4.2-manual/da8d189bb5cc60f2.md?wd=4.2
[5] https://www.mongodb.com/docs/v4.2/reference/operator/aggregation/currentOp/
[6] https://www.mongodb.com/docs/v7.0/reference/method/db.killOp/
[7] https://www.mongodb.com/docs/v7.0/reference/method/db.killop/
[8] https://www.mongodb.com/docs/manual/reference/command/killSessions/
[9] https://www.mongodb.com/docs/v3.6/reference/command/killSessions/
[10] https://www.mongodb.com/docs/manual/reference/method/db.killop/
[11] https://www.mongodb.com/docs/manual/reference/privilege-actions/
[12] https://stackoverflow.com/questions/23360007/mongodb-current-op
[13] https://www.mongodb.com/docs/manual/reference/command/killAllSessions/
[14] https://www.percona.com/blog/whats-running-in-my-db-a-journey-with-currentop-in-mongodb/
[15] https://mongoing.com/docs/reference/method/db.currentOp.html
[16] https://www.mongodb.com/docs/manual/reference/command/killOp/
[17] https://hackernoon.com/mongodb-currentop-18fe2f9dbd68
[18] https://dba.stackexchange.com/questions/60029/how-do-i-safely-kill-long-running-operations-in-mongodb
[19] https://www.mongodb.com/docs/manual/reference/command/currentOp/
[20] https://www.mongodb.com/community/forums/t/why-does-db-currentop-output-the-hello-command/132603
[21] https://www.w3resource.com/mongodb/shell-methods/database/db-currentOp.php
[22] https://stackoverflow.com/questions/26940616/how-do-i-abort-a-running-query-in-the-mongodb-shell
[23] https://www.xuchao.org/docs/mongodb/reference/method/db.currentOp.html
[24] https://gist.github.com/kylemclaren/3c09a4dda5991cf0bf9c
[25] https://stackoverflow.com/questions/61637710/weird-operation-in-db-currentop-output-in-mongodb
[26] https://www.mongodb.com/docs/manual/tutorial/terminate-running-operations/
[27] https://studio3t.com/knowledge-base/articles/mongodb-current-operations/
[28] https://serverfault.com/questions/585170/how-to-find-kill-long-running-mongo-scripts
[29] https://stackoverflow.com/questions/22725814/view-progress-of-long-running-mongodb-aggregation-job
[30] https://www.mongodb.com/community/forums/t/using-mongocxx-aggregation-with-current-op/174127
[31] https://www.mongodb.com/docs/manual/reference/operator/aggregation-pipeline/
[32] https://www.mongodb.com/community/forums/t/aggregation-on-currentop/282006
[33] https://pub.dev/documentation/mongo_db_driver/latest/mongo_db_driver/$currentOp-class.html
[34] https://www.mongodb.com/docs/manual/reference/command/aggregate/
[35] https://www.mongodb.com/docs/v4.4/reference/method/db.killop/
[36] https://www.docs4dev.com/docs/en/mongodb/v3.6/reference/reference-operator-aggregation-currentOp.html
[37] https://github.com/mongodb/docs/blob/master/source/reference/command/currentOp.txt
[38] https://docs.huihoo.com/mongodb/3.4/reference/command/killOp/index.html
[39] https://www.bookstack.cn/read/mongodb-4.2-manual/13cdda0fa03edd08.md
[40] https://www.mongodb.com/docs/manual/aggregation/
[41] https://www.prisma.io/dataguide/mongodb/authorization-and-privileges
[42] https://www.mongodb.com/docs/manual/reference/built-in-roles/
[43] https://www.docs4dev.com/docs/en/mongodb/v3.6/reference/reference-command-killSessions.html
[44] https://www.youtube.com/watch?v=le6j_4REOM4
[45] https://stackoverflow.com/questions/47060975/access-currentop-through-java-mongo-3-4-driver-or-spring-data-mongo
[46] https://stackoverflow.com/questions/62407737/mongodb-java-driver-kill-running-aggegation
[47] https://mongoing.com/docs/reference/privilege-actions.html
[48] http://www.mongodb.com/docs/v3.6/reference/command/currentOp/
[49] https://www.bookstack.cn/read/mongodb-4.2-manual/c46d5c386f5bf43f.md
[50] https://www.mongodb.com/docs/compass/current/connect/required-access/