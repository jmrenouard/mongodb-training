Voici des réponses précises à tes questions, selon les meilleures pratiques MongoDB actuelles :

## ⚙️ La copie est-elle automatique ?

**Oui, la copie des données est automatique lors de l’ajout d’un nouveau membre secondaire dans un replica set.**  
MongoDB effectue une synchronisation initiale (*initial sync*) qui copie toutes les données du primaire (ou d’un autre secondaire) vers le nouveau membre, puis applique en continu les modifications via l’oplog pour garder les données à jour[1][2].  
Ce processus est géré automatiquement par MongoDB, sans intervention manuelle nécessaire lors du déploiement standard.

## 💾 Où se trouvent les oplog ?

**Les oplog sont stockés dans la base de données locale (`local`) de chaque membre du replica set, dans la collection `oplog.rs`.**  
Cette collection est une collection *capped*, ce qui signifie qu’elle a une taille maximale fixée et que les anciennes entrées sont automatiquement écrasées quand la taille maximale est atteinte[3][2].

> **Chemin typique** :  
> `/data/db/local/oplog.rs` (ou selon le chemin configuré pour la base `local` sur chaque serveur MongoDB)

## ⚙️ Comment paramétrer les oplog ?

**La configuration principale de l’oplog concerne sa taille.**  
Par défaut, MongoDB alloue une partie de l’espace disque disponible pour l’oplog, mais il est possible (et souvent recommandé) de la configurer manuellement pour garantir une période de rétention suffisante pour les opérations de réplication.

**Pour modifier la taille de l’oplog :**
```javascript
use local
db.runCommand({ replSetResizeOplog: 1, size: 16000 })
```
Cette commande définit la taille de l’oplog à 16 Go (remplace `16000` par la taille souhaitée en mégaoctets)[3].

> **Remarque** :  
> - Il faut exécuter cette commande sur chaque membre du replica set.
> - La taille minimale recommandée est de 990 Mo.
> - Le paramètre `replSetResizeOplog` est disponible depuis MongoDB 3.6+.

## ⚙️ Comment configurer le chemin des opllog ?

**Le chemin de l’oplog n’est pas configurable indépendamment.**  
L’oplog est une collection de la base `local`, donc il suit le chemin de stockage de la base de données `local`.  
Pour modifier ce chemin, il faut configurer le chemin de stockage global de MongoDB via le paramètre `storage.dbPath` dans le fichier de configuration (`mongod.conf`)[4].

**Exemple de configuration :**
```yaml
storage:
  dbPath: /data/mongo
```
Toutes les bases, y compris `local`, seront alors stockées dans `/data/mongo`.

> **Attention :**  
> - Il n’est pas possible de déplacer uniquement l’oplog sans déplacer toute la base `local`.
> - Changer le chemin de stockage après le démarrage du service nécessite une procédure spécifique (arrêt, déplacement des fichiers, redémarrage).

## 📊 Résumé

| Question                                  | Réponse                                                                                  |
|--------------------------------------------|------------------------------------------------------------------------------------------|
| La copie est-elle automatique ?            | Oui, synchronisation initiale automatique puis réplication via oplog                     |
| Où sont les oplog ?                        | Dans la base `local`, collection `oplog.rs` de chaque membre                             |
| Comment paramétrer la taille de l’oplog ?  | `db.runCommand({ replSetResizeOplog: 1, size: TAILLE_EN_MO })`                           |
| Comment configurer le chemin de l’oplog ?  | Configurer `storage.dbPath` dans `mongod.conf` pour modifier le chemin de la base `local`|

## ⚠️ Points de vigilance

- **Taille de l’oplog** : Une taille trop petite peut entraîner des échecs de synchronisation si le secondaire ne peut pas rattraper le retard à cause d’opérations écrasées.
- **Chemin de stockage** : Changer le chemin après le démarrage nécessite une manipulation délicate des fichiers de données.
- **Sécurité** : Protégez la base `local` car elle contient des informations sensibles pour la réplication.

**En résumé :**  
La synchronisation et la réplication sont automatiques. L’oplog réside dans `local.oplog.rs` et son chemin dépend du `dbPath` global. La taille de l’oplog se configure via une commande spécifique, pas via un fichier de configuration[3][2][4].

[1] https://www.mongodb.com/docs/manual/core/replica-set-sync/
[2] https://www.mydbops.com/blog/decoding-mongodb-oplog-storage-usage-insights
[3] https://www.xuchao.org/docs/mongodb/tutorial/change-oplog-size.html
[4] https://stackoverflow.com/questions/27688673/mongodb-data-files-created-in-wrong-directory-while-changing-oplog-size
[5] https://www.mongodb.com/docs/ops-manager/current/tutorial/manage-oplog-storage/
[6] https://www.ibm.com/docs/SSM21Y_latest/datacollector/UserGuide/Origins/MongoDBOplog.html
[7] https://www.mongodb.com/docs/manual/replication/
[8] https://www.xuchao.org/docs/mongodb/core/replica-set-sync.html
[9] https://www.mongodb.com/docs/manual/core/replica-set-oplog/
[10] https://www.mongodb.com/docs/manual/tutorial/change-oplog-size/
[11] https://www.mongodb.com/community/forums/t/oplog-window-best-practice-value/215225
[12] https://stackoverflow.com/questions/22222671/how-to-see-oplog-in-standalone-mongodb
[13] https://www.mongodb.com/docs/atlas/reference/atlas-oplog/
[14] https://www.mongodb.com/docs/ops-manager/current/admin/backup/oplog-stores-page/
[15] https://www.mongodb.com/community/forums/t/mongodb-using-oplog-for-incremental-backups/289347
[16] https://www.mongodb.com/community/forums/t/enable-configure-oplog-on-standalone-mongodb-version-5/193146
[17] https://stackoverflow.com/questions/20487002/oplog-enable-on-standalone-mongod-not-for-replicaset
[18] https://www.mongodb.com/docs/ops-manager/v5.0/tutorial/manage-s3-oplog-storage/
[19] https://dba.stackexchange.com/questions/245262/mongodb-replica-set-sync-data-by-copying-data-files-from-another-member
[20] https://stackoverflow.com/questions/47604400/mongodb-replication-automatically
[21] https://severalnines.com/blog/replica-set-data-synchronization-after-restoring-a-mongodb-backup/
[22] https://stackoverflow.com/questions/32368194/how-sync-between-replica-sets-in-mongodb-achieved-automatic-or-manual-triggerin
[23] https://www.solarwinds.com/blog/an-introduction-to-mongodb-replication-and-replica-sets
[24] https://www.mongodb.com/docs/manual/tutorial/resync-replica-set-member/
[25] https://dba.stackexchange.com/questions/302891/creating-a-copy-of-a-mongodb-replica-set
[26] https://help.galaxycloud.app/en/article/mongodb-oplog-user-setup-wnas22/
[27] https://www.alibabacloud.com/help/en/mongodb/use-cases/best-practices-and-risks-for-oplog-settings
[28] http://docs.asprain.cn/mongodb/tutorial/change-oplog-size.html
[29] https://tuttlem.github.io/2014/06/13/how-to-setup-an-oplog-on-a-single-mongodb-instance.html
[30] https://www.mongodb.com/docs/ops-manager/current/tutorial/manage-s3-oplog-storage/
[31] https://docs.streamsets.com/platform-datacollector/latest/datacollector/UserGuide/Origins/MongoDBOplog.html
[32] https://github.com/VeliovGroup/ostrio/blob/master/tutorials/mongodb/enable-oplog.md