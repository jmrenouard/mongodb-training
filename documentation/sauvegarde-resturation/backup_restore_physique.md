Voici une description détaillée des procédures de sauvegarde physiques et logiques dans MongoDB, accompagnée des commandes, des avantages et des inconvénients.

## 🛠️ Types de sauvegarde MongoDB

### Sauvegarde logique

La sauvegarde logique consiste à extraire les données au niveau applicatif, généralement via des outils comme `mongodump` et `mongorestore`. Elle permet d’obtenir une copie cohérente des données, des index et des métadonnées, mais nécessite un traitement supplémentaire pour reconstituer la base.

- **Commandes principales :**
  - **Sauvegarde :**
    ```bash
    mongodump --db  --out /chemin/vers/backup
    ```
    Pour sauvegarder toutes les bases :
    ```bash
    mongodump --out /chemin/vers/backup
    ```
    Pour une collection spécifique :
    ```bash
    mongodump --db  --collection  --out /chemin/vers/backup
    ```
  - **Restauration :**
    ```bash
    mongorestore --db  --drop /chemin/vers/backup/
    ```
    Pour restaurer une collection :
    ```bash
    mongorestore --db  --collection  /chemin/vers/backup//.bson
    ```
- **Paramètres clés :**
  - `--db` : nom de la base à sauvegarder/restaurer.
  - `--collection` : nom de la collection à cibler.
  - `--out` : dossier de destination de la sauvegarde.
  - `--drop` : supprime la base avant restauration pour éviter les conflits[1][2].

- **Avantages :**
  - **Portabilité** : sauvegarde facilement transportable et restaurée sur n’importe quel serveur MongoDB.
  - **Granularité** : possibilité de sauvegarder/restaurer une base, une collection, ou même le résultat d’une requête.
  - **Simplicité** : outils natifs, bien documentés, adaptés aux petites/moyennes bases[1][2].

- **Inconvénients :**
  - **Durée** : temps de sauvegarde/restauration long pour de gros volumes de données (reconstruction des index, etc.).
  - **Consommation de ressources** : peut impacter les performances du serveur pendant la sauvegarde (notamment sur des bases volumineuses).
  - **Non atomique** : sans verrouillage (`fsyncLock`), la cohérence temporelle n’est pas garantie[2][3].

### Sauvegarde physique

La sauvegarde physique consiste à copier les fichiers de données bruts du système de fichiers sur lequel MongoDB stocke ses données, ou à utiliser des snapshots du système de fichiers.

- **Commandes principales :**
  - **Verrouillage de la base (optionnel, pour garantir la cohérence) :**
    ```bash
    db.fsyncLock()
    ```
    (à exécuter dans le shell MongoDB)
  - **Copie des fichiers de données :**
    ```bash
    cp -r /chemin/vers/dossier/data /chemin/vers/backup
    ```
  - **Déverrouillage de la base :**
    ```bash
    db.fsyncUnlock()
    ```
  - **Utilisation de snapshots :**
    - Selon l’infrastructure (LVM, ZFS, SAN, etc.), possibilité de créer un snapshot instantané du volume contenant les données MongoDB.
    - Exemple (LVM) :
      ```bash
      lvcreate --snapshot --size 1G --name mongo_snapshot /dev/vg/mongo_data
      ```
- **Paramètres clés :**
  - **Chemin des données** : `/var/lib/mongodb` (par défaut sous Linux).
  - **Taille du snapshot** : doit être suffisante pour capturer toutes les modifications pendant la copie.
  - **Durée du verrouillage** : doit être la plus courte possible pour limiter l’impact sur les applications[3].

- **Avantages :**
  - **Rapidité** : très rapide pour de gros volumes de données.
  - **Cohérence** : si le système de fichiers est verrouillé, la sauvegarde est atomique et cohérente.
  - **Peu d’impact** : peu de consommation de ressources CPU/mémoire (sauf si snapshot non supporté par le matériel)[3].

- **Inconvénients :**
  - **Dépendance à l’infrastructure** : nécessite des outils spécifiques pour les snapshots (LVM, ZFS, SAN, etc.).
  - **Moins portable** : la restauration doit se faire sur un système compatible (même version de MongoDB, même architecture).
  - **Complexité** : gestion des snapshots, verrouillage/déverrouillage, gestion des droits d’accès[3].

## 📊 Tableau comparatif : Sauvegarde logique vs physique

| Critère                | Sauvegarde logique          | Sauvegarde physique           |
|------------------------|-----------------------------|-------------------------------|
| Outils                 | mongodump / mongorestore    | fsyncLock / snapshot / cp     |
| Portabilité            | Excellente                  | Limitée (version/architecture)|
| Rapidité               | Lente (gros volumes)        | Rapide                        |
| Cohérence              | Optionnelle (fsyncLock)     | Atomique (si verrouillée)     |
| Impact performance     | Moyen/élevé                 | Faible                        |
| Infrastructure requise | Aucune                      | Spécifique (LVM, SAN, etc.)   |
| Granularité            | Base/collection/requête     | Toute la base                 |

## ⚠️ Points de vigilance

- **Cohérence des données** : sans verrouillage, la sauvegarde logique peut être incohérente en cas d’écritures concurrentes.
- **Taille des sauvegardes** : la sauvegarde logique peut occuper plus d’espace que les fichiers bruts (notamment avec les index).
- **Sécurité** : les fichiers de sauvegarde doivent être protégés contre l’accès non autorisé.
- **Risque de perte de données** : en cas de problème lors de la restauration ou de la copie, des données peuvent être perdues ou corrompues[4][1].

## 💻 Exemples pratiques

**Sauvegarde logique automatisée (cron) :**
```bash
3 3 * * * mongodump --out /var/backups/mongobackups/$(date +"%m-%d-%y")
```
**Suppression des sauvegardes anciennes :**
```bash
1 3 * * * find /var/backups/mongobackups/ -mtime +7 -exec rm -rf {} \;
```
**Sauvegarde physique (snapshot LVM) :**
```bash
db.fsyncLock()
lvcreate --snapshot --size 1G --name mongo_snapshot /dev/vg/mongo_data
db.fsyncUnlock()
```


En résumé, le choix entre sauvegarde logique et physique dépend de la taille des données, des contraintes de temps, de l’infrastructure disponible et des exigences de portabilité. La sauvegarde logique est plus flexible et portable, mais plus lente pour les gros volumes, tandis que la sauvegarde physique est rapide mais dépendante de l’infrastructure sous-jacente.

[1] https://www.digitalocean.com/community/tutorials/how-to-back-up-restore-and-migrate-a-mongodb-database-on-ubuntu-20-04-fr
[2] https://cursa.app/fr/page/sauvegarde-et-restauration-dans-mongodb
[3] https://www.programmevitam.fr/ressources/DocCourante/html/exploitation/topics/17-backup_restore_gros_volume.html
[4] https://fr.linkedin.com/advice/0/what-backup-solutions-work-best-mongodb-skills-database-development-59e5e?lang=fr&lang=fr
[5] https://kinsta.com/fr/blog/mongodb-vs-mysql/
[6] https://fr.wisdominterface.com/blogs/comprendre-les-avantages-et-les-inconvenients-de-mongodb/
[7] https://www.ionos.fr/digitalguide/hebergement/aspects-techniques/mysql-vs-mongodb/
[8] https://www.ionos.fr/digitalguide/sites-internet/developpement-web/mongodb-queries/
[9] https://www.purestorage.com/fr/knowledge/what-is-mongodb.html
[10] https://www.astera.com/fr/type/blog/mongodb-vs-mysql/
[11] https://www.joinsecret.com/fr/mongodb/reviews
[12] https://www.rubrik.com/fr/insights/how-to-back-up-mongodb-databases
[13] https://www.ibm.com/docs/fr/spp/10.1.17?topic=mongodb-restoring-data
[14] https://learn.microsoft.com/fr-fr/azure/aks/deploy-mongodb-cluster
[15] https://www.youtube.com/watch?v=fyza2KdpllE
[16] https://www.infoq.com/fr/articles/mongodb-deployment-monitoring/
[17] https://datascientest.com/sql-vs-nosql-differences-utilisations-avantages-et-inconvenients
[18] https://kinsta.com/fr/blog/dynamodb-vs-mongodb/