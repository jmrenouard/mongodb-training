Voici les **autres mots-clés et opérateurs importants** pour structurer une pipeline d’agrégation MongoDB, en complément des principaux (`$match`, `$group`, `$sort`, `$project`, `$unwind`, `$lookup`, `$limit`, `$skip`, `$out`, `$merge`, `$addFields`)[1][2][3].

## 🔍 Autres mots-clés et opérateurs essentiels

| Mot-clé/Opérateur      | Description                                                                                           |
|------------------------|-------------------------------------------------------------------------------------------------------|
| **$facet**             | Permet d’exécuter plusieurs pipelines en parallèle sur le même lot de documents                       |
| **$bucket**            | Groupe les documents en intervalles définis (buckets) selon une expression                            |
| **$bucketAuto**        | Groupe les documents en intervalles de taille égale, automatiquement déterminés                       |
| **$count**             | Ajoute un champ comptant le nombre de documents à ce stade                                            |
| **$redact**            | Contrôle l’accès aux documents selon des conditions de sécurité                                       |
| **$replaceRoot**       | Remplace le document courant par un sous-document spécifié                                            |
| **$sample**            | Sélectionne aléatoirement un nombre donné de documents                                                |
| **$geoNear**           | Trie les documents selon la proximité géographique                                                    |
| **$indexStats**        | Renvoie des statistiques sur les index utilisés par la collection                                     |
| **$graphLookup**       | Effectue une recherche récursive sur une collection (graphes, hiérarchies)                            |
| **$setWindowFields**   | Applique des fonctions de fenêtre (window functions) sur les documents (MongoDB 5.0+)                 |
| **$densify**           | Ajoute des documents pour créer des séquences continues (ex : dates manquantes)                       |
| **$fill**              | Remplit les valeurs nulles dans un champ selon une logique spécifique                                 |
| **$documents**         | Génère des documents à partir de valeurs littérales                                                   |
| **$collStats**         | Renvoie des statistiques sur la collection                                                            |
| **$currentOp**         | Renvoie les opérations en cours sur la base de données (système)                                      |

## 🧩 Exemple de pipeline complet avec opérateurs avancés

```javascript
db.orders.aggregate([
  { $match: { region: "EMEA" } },
  { $lookup: { from: "books", localField: "items.book_id", foreignField: "_id", as: "book_details" } },
  { $unwind: "$book_details" },
  { $facet: {
      "totalSales": [
        { $group: { _id: null, total: { $sum: "$items.price" } } }
      ],
      "topBooks": [
        { $group: { _id: "$book_details.title", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 5 }
      ]
    }
  },
  { $replaceRoot: { newRoot: { $mergeObjects: [ "$totalSales", "$topBooks" ] } } }
])
```
> *Remarque : Ce pipeline illustre l’utilisation de `$facet` et `$replaceRoot`.*

Pour construire une pipeline d’agrégation efficace avec MongoDB, il est nécessaire de maîtriser les **stages essentiels** qui permettent de filtrer, transformer, regrouper et organiser les données. Voici les principaux stages à connaître :

## 🧩 Stages essentiels pour une pipeline d’agrégation efficace

| Stage           | Description                                                                                         | Utilité principale                       |
|-----------------|-----------------------------------------------------------------------------------------------------|------------------------------------------|
| **$match**      | Filtre les documents selon des critères spécifiques                                                 | Réduire le volume de données à traiter[1][2][3] |
| **$group**      | Regroupe les documents par un ou plusieurs champs et applique des fonctions d’agrégation            | Calculer des agrégats, comptes, moyennes[1][2][4] |
| **$project**    | Sélectionne, renomme ou calcule des champs dans les documents de sortie                             | Réduire la taille des documents, créer de nouveaux champs[2][5][4] |
| **$sort**       | Trie les documents selon un ou plusieurs champs                                                     | Ordonner les résultats[1][2][4]          |
| **$unwind**     | Décompose un tableau en plusieurs documents (un par élément du tableau)                             | Traiter les tableaux de façon individuelle[5][6] |
| **$lookup**     | Effectue une jointure avec une autre collection                                                     | Enrichir les documents avec des données externes[5][6] |
| **$limit**      | Limite le nombre de documents passés à l’étape suivante                                             | Limiter le volume de résultats[5][4]     |
| **$skip**       | Ignore un nombre donné de documents                                                                 | Paginer les résultats[5][4]              |

## 🔍 Bonnes pratiques pour l’efficacité

- **Placer `$match` le plus tôt possible** : Cela réduit le nombre de documents traités dans les étapes suivantes et améliore la performance[1][7][3].
- **Utiliser les index** : Les stages `$match` et `$sort` peuvent bénéficier d’index pour accélérer les requêtes[7].
- **Limiter les champs avec `$project`** : Ne garder que les champs nécessaires réduit la charge mémoire et réseau[2][4].
- **Utiliser `$group` pour les agrégations** : Indispensable pour calculer des totaux, moyennes, comptes, etc.[1][2][4]
- **Trier avec `$sort`** : Utile pour présenter les résultats de façon lisible ou préparer une pagination[1][2][4].
- **Joindre avec `$lookup`** : Pour enrichir les documents avec des données d’autres collections[5][6].

## 📝 Synthèse

Pour une pipeline d’agrégation efficace, commencez par filtrer (`$match`), puis regroupez (`$group`), projetez (`$project`), triez (`$sort`), et limitez (`$limit`/`$skip`) selon vos besoins. Utilisez `$unwind` pour traiter les tableaux et `$lookup` pour joindre des collections.  
Ces stages sont la base d’une pipeline robuste et performante pour l’analyse et la transformation de données dans MongoDB[1][2][5].

Outre les principaux opérateurs, MongoDB propose de nombreux **mots-clés avancés** pour structurer, transformer et analyser les données dans une pipeline d’agrégation :  
- **$facet** pour exécuter plusieurs pipelines en parallèle,  
- **$bucket**/**$bucketAuto** pour le groupement par intervalles,  
- **$count** pour compter les documents,  
- **$redact**, **$replaceRoot**, **$sample**, **$geoNear**, **$graphLookup**, **$setWindowFields**, **$densify**, **$fill**, **$documents**, **$collStats**, **$currentOp** pour des besoins spécifiques (sécurité, géolocalisation, graphes, statistiques, etc.)[1][2][3].

Ces opérateurs permettent de répondre à des besoins analytiques et structurels complexes, en complément des fonctions d’agrégation et de projection classiques.

[1] https://studio3t.com/knowledge-base/articles/mongodb-aggregation-framework/

[2] https://www.codecademy.com/article/mongodb-aggregation

[3] https://www.prisma.io/dataguide/mongodb/mongodb-aggregation-framework

[4] https://www.mydbops.com/blog/mongodb-aggregation-guide

[5] https://www.singlestore.com/blog/understanding-the-aggregation-operator-in-mongodb/

[6] https://www.mongodb.com/docs/manual/core/aggregation-pipeline/

[7] https://www.mongodb.com/docs/manual/reference/operator/aggregation/

[8] https://www.mongodb.com/resources/products/capabilities/aggregation-pipeline

[9] https://mongopilot.com/top-10-mongodb-aggregation-operators-you-should-master/

[10] https://stackoverflow.com/questions/78777177/how-to-optimize-mongodb-aggregation-pipeline-with-keyword-search-and-sorting-for




[1] https://studio3t.com/fr/knowledge-base/articles/mongodb-aggregation-framework/
[2] https://www.codecademy.com/article/mongodb-aggregation
[3] https://www.linkedin.com/pulse/8-important-pipeline-stages-aggregation-mongodb-hamza-siddique-dqvtf
[4] https://www.ionos.fr/digitalguide/sites-internet/developpement-web/mongodb-aggregation/
[5] https://learn.microsoft.com/fr-fr/azure/cosmos-db/mongodb/tutorial-aggregation
[6] https://floqast.com/fr/ingenierie-blog/poste/introduction-aux-agregations-mongodb-la-puissance-de-la-transformation-des-donnees/
[7] https://studio3t.com/knowledge-base/articles/mongodb-aggregation-framework/
[8] https://www.datacamp.com/fr/tutorial/mongodb-aggregation-pipeline-pymongo
[9] https://cursa.app/fr/page/travailler-avec-un-pipeline-d-agregation
[10] https://fr.blog.businessdecision.com/tutoriel-mongodb-agregation/