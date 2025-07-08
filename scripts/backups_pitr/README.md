# **📚 Documentation des Stratégies de Sauvegarde et Restauration MongoDB**

Cette documentation explique le fonctionnement des scripts Bash que nous avons développés pour gérer les sauvegardes complètes et incrémentielles de MongoDB, ainsi que leur processus de restauration.

## **1\. 💾 Stratégie de Sauvegarde MongoDB**

La stratégie de sauvegarde repose sur l'utilisation de mongodump pour créer des copies de vos bases de données. Nous distinguons deux types de sauvegardes : complètes et incrémentielles, s'appuyant sur le journal d'opérations (oplog) de MongoDB.

### **1.1. 💡 Concepts Clés**

* **Sauvegarde Complète (Full Backup)** : C'est une copie intégrale de toutes les données d'une base de données (ou de toutes les bases) à un instant "T". Elle sert de point de départ pour toute restauration.  
* **Sauvegarde Incrémentielle (Incremental Backup)** : Elle ne contient que les modifications (insertions, mises à jour, suppressions) qui se sont produites depuis la dernière sauvegarde (complète ou incrémentielle). Pour MongoDB, cela est réalisé en capturant une partie de l'oplog.  
* **Oplog (Operation Log)** : C'est un journal spécial dans MongoDB qui enregistre toutes les opérations d'écriture effectuées sur la base de données. Il est essentiel pour la réplication et, dans notre cas, pour les sauvegardes incrémentielles. Il est activé par défaut sur les replica sets.

### **1.2. 📜 Le Script de Sauvegarde (mongodb\_backup.sh)**

Ce script automatise la création et la gestion des sauvegardes.

#### **1.2.1. Fonctionnement de la Sauvegarde Complète (full)**

Lorsque vous exécutez le script avec l'argument full (./mongodb\_backup.sh full), les étapes suivantes sont réalisées :

1. **Création du Répertoire** : Un nouveau répertoire est créé sous BACKUP\_DIR/full/ avec un horodatage (YYYYMMDD\_HHmmss) comme nom (ex: /data/mongodb\_backups/full/20240707\_103000).  
2. **Capture du Timestamp Oplog Initial** : Avant de lancer le mongodump, le script interroge l'oplog pour obtenir son timestamp actuel. Ce timestamp est crucial car il marque le point de départ des futures sauvegardes incrémentielles. Il est enregistré dans un fichier oplog\_start\_timestamp.txt à l'intérieur du répertoire de la sauvegarde complète.  
3. **Exécution de mongodump** : La commande mongodump est exécutée pour exporter toutes les données de la base de données (ou des bases spécifiées par DB\_NAME) vers le répertoire nouvellement créé.  
4. **Mise à Jour du Fichier de Référence Oplog** : Le timestamp de l'oplog capturé à l'étape 2 est copié dans le fichier oplog\_timestamp.txt à la racine de BACKUP\_DIR. Ce fichier servira de référence pour la prochaine sauvegarde incrémentielle.  
5. **Rotation des Sauvegardes** : Les anciennes sauvegardes complètes (plus anciennes que FULL\_BACKUP\_RETENTION jours) sont supprimées pour gérer l'espace disque.

#### **1.2.2. Fonctionnement de la Sauvegarde Incrémentielle (incremental)**

Lorsque vous exécutez le script avec l'argument incremental (./mongodb\_backup.sh incremental), voici ce qui se passe :

1. **Vérification du Timestamp Oplog** : Le script lit le dernier timestamp de l'oplog enregistré dans oplog\_timestamp.txt. C'est le point à partir duquel les nouvelles modifications doivent être capturées. **Une sauvegarde complète doit avoir été exécutée au préalable pour initialiser ce fichier.**  
2. **Identification de la Sauvegarde Complète de Référence** : Le script trouve la dernière sauvegarde complète effectuée. Les sauvegardes incrémentielles sont stockées dans un sous-répertoire du répertoire incremental qui porte le même nom que le répertoire de la sauvegarde complète de référence (ex: /data/mongodb\_backups/incremental/20240707\_103000/).  
3. **Création du Répertoire Incrémentiel** : Un nouveau répertoire est créé sous le répertoire de la sauvegarde complète de référence, avec un préfixe inc\_ et un horodatage (ex: /data/mongodb\_backups/incremental/20240707\_103000/inc\_20240707\_110000/).  
4. **Exécution de mongodump \--oplogLimit** : La commande mongodump est exécutée avec l'option \--oplogLimit en utilisant le timestamp de l'oplog lu précédemment. Cela indique à mongodump de n'exporter que les opérations de l'oplog qui se sont produites *après* ce timestamp. Le résultat est un fichier oplog.bson contenant ces opérations.  
5. **Mise à Jour du Nouveau Timestamp Oplog** : Après la sauvegarde incrémentielle, un nouveau timestamp de l'oplog est capturé (le timestamp actuel du serveur) et mis à jour dans oplog\_timestamp.txt. Ce sera le point de départ pour la *prochaine* sauvegarde incrémentielle.  
6. **Rotation des Sauvegardes** : Les anciennes sauvegardes incrémentielles (plus anciennes que INCREMENTAL\_BACKUP\_RETENTION jours) sont supprimées pour la sauvegarde complète de référence correspondante.

### **1.3. 📁 Structure des Répertoires de Sauvegarde**

/data/mongodb\_backups/  
├── full/  
│   ├── 20240707\_103000/          \# Sauvegarde complète du 7 juillet 2024 à 10h30  
│   │   ├── \<dump\_de\_la\_db\>/      \# Contenu de la base de données  
│   │   └── oplog\_start\_timestamp.txt \# Timestamp de l'oplog au début de cette full  
│   ├── 20240708\_020000/          \# Sauvegarde complète du 8 juillet 2024 à 2h00  
│   │   ├── ...  
│   └── ...  
└── incremental/  
    ├── 20240707\_103000/          \# Incrémentielles basées sur la full du 7 juillet 10h30  
    │   ├── inc\_20240707\_110000/  \# Incrémentielle du 7 juillet 11h00  
    │   │   └── oplog.bson        \# Fichier d'oplog  
    │   ├── inc\_20240707\_120000/  \# Incrémentielle du 7 juillet 12h00  
    │   │   └── oplog.bson  
    │   └── ...  
    ├── 20240708\_020000/          \# Incrémentielles basées sur la full du 8 juillet 2h00  
    │   ├── inc\_20240708\_030000/  
    │   │   └── oplog.bson  
    │   └── ...  
    └── ...

mongodb\_backup.log               \# Fichier de log des opérations de sauvegarde  
oplog\_timestamp.txt              \# Fichier temporaire pour le dernier timestamp d'oplog utilisé

## **2\. 🔄 Stratégie de Restauration MongoDB**

La restauration d'une base de données à partir de sauvegardes complètes et incrémentielles est un processus en deux étapes : d'abord la restauration de la base complète, puis l'application des modifications incrémentielles.

### **2.1. 💡 Concept de Restauration Incrémentielle**

La restauration incrémentielle ne consiste pas à "fusionner" des fichiers, mais à "rejouer" les opérations. Pour restaurer à un certain point dans le temps, il faut :

1. Rétablir une sauvegarde complète qui précède ou inclut ce point.  
2. Appliquer ensuite, dans l'ordre chronologique, tous les dumps d'oplog incrémentiels pertinents jusqu'au point de restauration désiré.

### **2.2. 📜 Le Script de Restauration (mongodb\_restore.sh)**

Ce script automatise le processus de restauration incrémentielle.

#### **2.2.1. Processus de Restauration**

Le script prend en argument le nom du répertoire de la sauvegarde complète à partir de laquelle vous souhaitez restaurer (ex: 20240707\_103000).

1. **Étape 1: Restauration de la Sauvegarde Complète**  
   * Le script localise le répertoire de la sauvegarde complète spécifiée (ex: /data/mongodb\_backups/full/20240707\_103000).  
   * Il exécute mongorestore avec l'option \--drop. Cette option est **très importante** car elle **supprime toutes les collections existantes** dans la base de données cible avant de restaurer les données de la sauvegarde complète. Cela garantit une base propre avant l'application des changements.  
   * La base de données est alors dans l'état exact où elle était au moment de la sauvegarde complète.

mongorestore \--host \<host\> \--port \<port\> \--drop /path/to/full\_backup\_dir

2. **Étape 2: Application des Sauvegardes Incrémentielles**  
   * Le script identifie le répertoire des sauvegardes incrémentielles associées à la sauvegarde complète restaurée (ex: /data/mongodb\_backups/incremental/20240707\_103000/).  
   * Il trouve tous les sous-répertoires inc\_YYYYMMDD\_HHmmss à l'intérieur, qui contiennent les fichiers oplog.bson.  
   * **Ordonnancement Crucial** : Les répertoires incrémentiels sont triés chronologiquement pour garantir que les opérations sont appliquées dans le bon ordre.  
   * Pour chaque fichier oplog.bson trouvé, le script exécute mongorestore avec l'option \--oplogReplay. Cette option indique à mongorestore de rejouer les opérations contenues dans l'oplog sur la base de données cible.

mongorestore \--host \<host\> \--port \<port\> \--oplogReplay /path/to/incremental\_oplog.bson  
Chaque oplog.bson est appliqué séquentiellement, mettant à jour la base de données avec les changements survenus entre les points de sauvegarde.

#### **2.2.2. Fichier de Log de Restauration**

mongodb\_restore.log              \# Fichier de log des opérations de restauration

### **2.3. ⚠️ Considérations Importantes pour la Restauration**

* **Prudence avec \--drop** : L'option \--drop efface les données existantes. Utilisez-la avec la plus grande prudence, idéalement sur un environnement de test ou une base de données dédiée à la restauration.  
* **Intégrité de l'Oplog** : La réussite de la restauration incrémentielle dépend entièrement de l'intégrité et de la complétude des fichiers oplog.bson. Toute corruption ou fichier manquant peut entraîner une restauration incomplète ou une base de données incohérente.  
* **Point-in-Time Recovery** : Ce script restaure au dernier point incrémentiel disponible. Pour une restauration à un point précis dans le temps (par exemple, juste avant une erreur), il faudrait une logique plus avancée pour déterminer le dernier oplog.bson à appliquer et potentiellement utiliser \--oplogLimit sur ce dernier fichier avec un timestamp spécifique.  
* **Testez Toujours** : Avant d'implémenter ces scripts en production, effectuez des tests de sauvegarde et de restauration exhaustifs sur un environnement de développement ou de staging pour vous assurer qu'ils fonctionnent comme prévu et que les données sont restaurées correctement.  
* **Authentification** : Assurez-vous que les options d'authentification (MONGO\_RESTORE\_USER, MONGO\_RESTORE\_PASS) sont correctement configurées si votre serveur MongoDB cible le requiert.

Cette documentation devrait vous fournir une compréhension solide de votre système de sauvegarde et de restauration MongoDB. N'hésitez pas si vous avez d'autres questions ou si vous souhaitez approfondir certains aspects \!