Voici un comparatif des stratégies recommandées pour réaliser un upsert massif dans PostgreSQL et MongoDB, incluant les bonnes pratiques et exemples d’implémentation.

## 🚀 Stratégies d’Upsert Massif

### PostgreSQL

**1. Utilisation de `INSERT ... ON CONFLICT DO UPDATE`**

- **Description** : La méthode la plus efficace et native pour l’upsert massif en PostgreSQL.
- **Exemple** :
  ```sql
  INSERT INTO table_name (col1, col2, ...)
  VALUES (val1, val2, ...), (val3, val4, ...), ...
  ON CONFLICT (unique_constraint)
  DO UPDATE SET col1 = excluded.col1, col2 = excluded.col2;
  ```
- **Avantages** :
  - Combine insertion et mise à jour en une seule requête.
  - Réduit le nombre de round-trips vers la base de données.
  - Permet d’insérer ou de mettre à jour plusieurs lignes en une fois[1][2][3].
- **Paramètres clés** : Assurez-vous qu’une contrainte unique ou une clé primaire est définie sur la table.

**2. Batch Processing**

- **Description** : Diviser les opérations upsert en lots pour éviter les transactions trop volumineuses et optimiser la performance.
- **Exemple** :
  - Utiliser des outils ou scripts pour envoyer des lots de 100 à 1000 lignes à la fois.
- **Avantages** :
  - Réduit la charge mémoire et les verrous.
  - Permet de traiter plus efficacement les conflits et de limiter les impacts sur la performance[4][5][6].

**3. Utilisation de tables temporaires et `COPY`**

- **Description** : Importer les données via `COPY` dans une table temporaire, puis utiliser `INSERT ... ON CONFLICT` pour transférer les données dans la table cible.
- **Exemple** :
  ```sql
  COPY temp_table FROM '/chemin/fichier.csv';
  INSERT INTO target_table
  SELECT * FROM temp_table
  ON CONFLICT (unique_constraint) DO UPDATE SET ...;
  ```
- **Avantages** :
  - Très efficace pour de très grands volumes de données.
  - Réduit la charge sur la table cible pendant l’import[7][1].

**4. Optimisation des index et du schéma**

- **Description** : Utiliser des index adaptés (B-tree, hash), optimiser les types de données et ajuster les paramètres serveur (`shared_buffers`, WAL sur disque séparé).
- **Avantages** :
  - Améliore la vitesse d’exécution des upserts[4][6].
- **Paramètres clés** :
  - `shared_buffers` : ajuster selon la RAM disponible.
  - Séparer le stockage des logs (WAL) et des données pour réduire la contention I/O.

### MongoDB

**1. Utilisation de `bulkWrite` avec `upsert: true`**

- **Description** : La méthode la plus efficace pour l’upsert massif en MongoDB.
- **Exemple** :
  ```javascript
  db.collection.bulkWrite([
    {
      updateOne: {
        filter: { _id: 1 },
        update: { $set: { name: "Alice" } },
        upsert: true
      }
    },
    {
      updateOne: {
        filter: { _id: 2 },
        update: { $set: { name: "Bob" } },
        upsert: true
      }
    }
  ], { ordered: false });
  ```
- **Avantages** :
  - Permet de traiter des milliers d’upserts en une seule opération.
  - Réduit le trafic réseau et la charge serveur.
  - Option `ordered: false` permet un traitement parallèle pour de meilleures performances[8][9][10].

**2. Batch Processing**

- **Description** : Envoyer les lots d’upserts par paquets de 100 à 1000 documents à la fois.
- **Avantages** :
  - Réduit la mémoire utilisée et la contention sur le serveur.
  - Facilite la gestion des erreurs et la reprise sur incident.

**3. Optimisation des index et des paramètres serveur**

- **Description** : S’assurer que les champs utilisés dans le filtre de l’upsert sont bien indexés.
- **Avantages** :
  - Accélère la phase de recherche avant l’insertion ou la mise à jour.
  - Réduit la charge CPU et I/O[9].
- **Paramètres clés** :
  - `writeConcern` : ajuster selon le niveau de durabilité souhaité.
  - Utiliser du matériel performant (SSD) pour les bases de données volumineuses.

**4. Utilisation de `updateMany` avec `upsert: true` (cas particuliers)**

- **Description** : Pour des mises à jour massives sur des critères simples.
- **Exemple** :
  ```javascript
  db.collection.updateMany(
    { status: "pending" },
    { $set: { status: "processed" } },
    { upsert: false }
  );
  ```
  > Note : `updateMany` ne permet l’upsert que si tous les documents répondent à un seul filtre, ce qui est rare pour un vrai upsert massif hétérogène.

## 📊 Tableau récapitulatif

| Stratégie                    | PostgreSQL                                         | MongoDB                                            |
|------------------------------|----------------------------------------------------|----------------------------------------------------|
| **Upsert natif**             | `INSERT ... ON CONFLICT DO UPDATE`                 | `bulkWrite` avec `upsert: true`                    |
| **Batch processing**         | Lots de 100-1000 lignes                            | Lots de 100-1000 documents                         |
| **Import via fichier**       | `COPY` vers table temporaire, puis upsert          | `mongoimport` (pas d’upsert direct)                |
| **Optimisation index**       | Index B-tree/hash, contraintes uniques             | Index sur les champs de filtre                     |
| **Paramètres serveur**       | `shared_buffers`, WAL sur disque séparé            | `writeConcern`, matériel SSD                       |

## ⚠️ Points de vigilance

- **PostgreSQL** : Les upserts massifs génèrent des "dead tuples" lors des mises à jour, ce qui peut nécessiter un autovacuum plus fréquent. Utilisez `ON CONFLICT DO NOTHING` si possible pour limiter ce phénomène[6].
- **MongoDB** : Les upserts massifs peuvent générer une forte charge sur le serveur. Surveillez la consommation de mémoire et ajustez la taille des lots selon la capacité du serveur[9][10].
- **Sécurité** : Limitez les accès aux opérations massives pour éviter les erreurs ou les attaques par déni de service.

## 💡 Résumé

- **PostgreSQL** : Utilisez `INSERT ... ON CONFLICT DO UPDATE` en lots, optimisez les index et les paramètres serveur, et privilégiez l’import via table temporaire pour les très gros volumes.
- **MongoDB** : Privilégiez `bulkWrite` avec `upsert: true`, envoyez les documents par lots, et assurez-vous que les champs de filtre sont indexés.

Ces stratégies garantissent des performances optimales pour l’upsert massif dans les deux systèmes.

[1] https://www.dbvis.com/thetable/postgresql-upsert-insert-on-conflict-guide/

[2] https://geshan.com.np/blog/2024/12/postgres-insert-on-conflict-update/

[3] https://bobcares.com/blog/postgres-bulk-upsert/

[4] https://risingwave.com/blog/top-techniques-to-enhance-upsert-speed-in-postgresql/

[5] https://www.reddit.com/r/PostgreSQL/comments/r7ayv3/postgres_upsert_query_performance/

[6] https://dba.stackexchange.com/questions/246990/postgres-upsert-performance-considerations-millions-of-rows-hour

[7] https://www.reddit.com/r/PostgreSQL/comments/kx8o23/bulk_insert_on_conflict_increment_counter/

[8] https://stackoverflow.com/questions/32019267/how-to-properly-do-a-bulk-upsert-update-in-mongodb

[9] https://www.dragonflydb.io/faq/mongodb-upsert-performance

[10] https://www.dragonflydb.io/faq/mongodb-bulk-insert-performance

[11] https://stackoverflow.com/questions/27093619/how-to-bulk-update-upsert-with-mongoid-mongodb

[12] https://www.mongodb.com/community/forums/t/bulk-upsert-for-historical-data/13890

[13] https://stackoverflow.com/questions/7019831/bulk-batch-update-upsert-in-postgresql

[14] https://www.reddit.com/r/PostgreSQL/comments/r0b5fg/upsert_on_a_huge_table/

[15] https://www.reddit.com/r/PostgreSQL/comments/n9w08l/best_practices_for_incremental_bulk_upsert/

[16] https://www.mongodb.com/docs/manual/reference/method/Bulk.find.upsert/

[17] https://www.mongodb.com/community/forums/t/what-is-the-correct-way-to-do-an-upsert/294181

[18] https://docs.capillarytech.com/docs/bulk-upsert-mongo

[19] https://stackoverflow.com/questions/47099064/update-upsert-with-bulkwrite-not-working

[20] https://www.mongodb.com/community/forums/t/taking-time-when-writing-3-million-records-to-the-db/254858