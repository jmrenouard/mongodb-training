Bien sûr, voici un tableau récapitulatif des principales **fonctions d’agrégation**, des **fonctions de projection** et des **opérateurs** MongoDB couramment utilisés dans les pipelines d’agrégation et les projections.

## 📊 Tableau récapitulatif des fonctions d’agrégation et de projection MongoDB

| Catégorie         | Opérateur/Fonction | Description synthétique                                                                 | Exemple d’utilisation (agrégation/projection)                |
|-------------------|--------------------|-----------------------------------------------------------------------------------------|--------------------------------------------------------------|
| **Agrégation**    | `$group`           | Regroupe les documents selon un critère, permet de calculer des agrégats                | `{ $group: { _id: "$pays", total: { $sum: "$prix" } } }`     |
|                   | `$match`           | Filtre les documents selon un critère                                                   | `{ $match: { age: { $gt: 18 } } }`                           |
|                   | `$project`         | Sélectionne ou transforme des champs dans le document                                   | `{ $project: { nom: 1, age: 1, _id: 0 } }`                   |
|                   | `$unwind`          | Décompose un tableau en plusieurs documents (un par élément du tableau)                 | `{ $unwind: "$items" }`                                      |
|                   | `$lookup`          | Jointure avec une autre collection                                                      | `{ $lookup: { from: "achats", localField: "id", foreignField: "client_id", as: "achats" } }` |
|                   | `$sort`            | Trie les documents selon un ou plusieurs champs                                         | `{ $sort: { age: -1 } }`                                     |
|                   | `$limit`           | Limite le nombre de documents retournés                                                 | `{ $limit: 10 }`                                             |
|                   | `$skip`            | Saute un nombre de documents                                                            | `{ $skip: 5 }`                                               |
|                   | `$addFields`       | Ajoute ou remplace des champs dans le document                                          | `{ $addFields: { total: { $sum: "$items.prix" } } }`         |
|                   | `$out`             | Écrit les résultats de l’agrégation dans une collection                                 | `{ $out: "resultats" }`                                      |
|                   | `$merge`           | Fusionne les résultats de l’agrégation dans une collection (ajout/mise à jour)          | `{ $merge: { into: "resultats" } }`                          |
| **Projection**    | `1` / `0`          | Inclusion/exclusion d’un champ dans le résultat                                         | `{ nom: 1, age: 1, _id: 0 }`                                 |
|                   | `$slice`           | Limite le nombre d’éléments d’un tableau à retourner                                    | `{ items: { $slice: 2 } }`                                   |
| **Fonctions**     | `$sum`             | Somme des valeurs d’un champ                                                            | `{ $sum: "$prix" }`                                          |
|                   | `$avg`             | Moyenne des valeurs d’un champ                                                          | `{ $avg: "$prix" }`                                          |
|                   | `$min`             | Valeur minimale d’un champ                                                              | `{ $min: "$prix" }`                                          |
|                   | `$max`             | Valeur maximale d’un champ                                                              | `{ $max: "$prix" }`                                          |
|                   | `$first`           | Premier élément d’un groupe                                                             | `{ $first: "$nom" }`                                         |
|                   | `$last`            | Dernier élément d’un groupe                                                             | `{ $last: "$nom" }`                                          |
|                   | `$push`            | Pousse des valeurs dans un tableau                                                      | `{ $push: "$nom" }`                                          |
|                   | `$addToSet`        | Pousse des valeurs uniques dans un tableau                                              | `{ $addToSet: "$nom" }`                                      |
| **Opérateurs**    | `$eq`, `$gt`, `$lt`, `$gte`, `$lte`, `$ne`, `$in`, `$nin` | Opérateurs de comparaison (égal, supérieur, inférieur, etc.) | `{ age: { $gt: 18 } }`                                       |
|                   | `$exists`          | Teste l’existence d’un champ                                                            | `{ age: { $exists: true } }`                                 |
|                   | `$type`            | Teste le type d’un champ                                                                | `{ age: { $type: "int" } }`                                  |
|                   | `$regex`           | Filtre selon une expression régulière                                                   | `{ nom: { $regex: /^A/ } }`                                  |
|                   | `$or`, `$and`      | Opérateurs logiques (ou, et)                                                            | `{ $or: [ { age: { $lt: 18 } }, { age: { $gt: 65 } } ] }`    |
|                   | `$not`             | Négation d’une condition                                                                | `{ age: { $not: { $lt: 18 } } }`                             |
|                   | `$cond`            | Conditionnelle (if-then-else)                                                           | `{ $cond: { if: { $gt: ["$prix", 50] }, then: "cher", else: "pas cher" } }` |

## 📝 Synthèse

- **Agrégation** : Permet de regrouper, filtrer, transformer, joindre, trier, limiter, sauter, ajouter des champs, écrire ou fusionner des résultats.
- **Projection** : Permet de sélectionner ou exclure des champs, limiter les éléments d’un tableau.
- **Fonctions** : Permettent de réaliser des calculs d’agrégation (somme, moyenne, min, max, etc.).
- **Opérateurs** : Permettent de comparer, tester, filtrer sur des expressions régulières, utiliser des conditions logiques.

Ce tableau couvre l’essentiel des opérateurs et fonctions utilisés dans les pipelines d’agrégation et les projections MongoDB.

