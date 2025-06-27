# mongodb-training
Repository for MongoDB training staff

Voici une page de documentation générale pour MongoDB, inspirée des ressources disponibles dans le dépôt `jmrenouard/mongodb-training` et adaptée à un format professionnel, clair et pédagogique.

# 🏗️ Documentation Générale MongoDB

## 📖 Introduction

MongoDB est une base de données NoSQL orientée documents, conçue pour la gestion de données structurées ou semi-structurées à grande échelle. Elle utilise un format proche du JSON appelé BSON pour stocker et échanger les données, offrant ainsi une grande flexibilité dans la modélisation et l’évolution des schémas[1][2][3].

## ✅ Avantages de MongoDB

- **Flexibilité du schéma** : Pas besoin de définir un schéma strict avant l’insertion, chaque document peut avoir des champs différents.
- **Scalabilité horizontale** : Prise en charge native du partitionnement (sharding) pour répartir les données sur plusieurs serveurs.
- **Haute disponibilité** : Utilisation de répliques (replica sets) pour assurer la redondance et la tolérance aux pannes.
- **Performances élevées** : Indexation avancée, agrégations puissantes et cache de requêtes.
- **Intégration multi-plateforme** : Disponible sur la plupart des systèmes d’exploitation et intégration facile avec de nombreux langages et frameworks[3].

## ❌ Inconvénients

- **Transactions complexes** : Les transactions ACID multi-documents sont possibles mais moins performantes que dans les bases relationnelles.
- **Consommation de ressources** : Peut nécessiter plus de mémoire et de stockage selon la volumétrie et la structure des données.
- **Courbe d’apprentissage** : Différents concepts (documents, collections, agrégations) à maîtriser par rapport aux bases relationnelles.

## ⚙️ Concepts Clés

- **Document** : Unité de base de stockage, similaire à un objet JSON, mais stocké en BSON.
- **Collection** : Groupe de documents, équivalent à une table dans une base relationnelle.
- **Base de données** : Ensemble de collections.
- **Index** : Structure pour accélérer les recherches.
- **Aggrégation** : Pipeline de traitements pour analyser et transformer les données.
- **Sharding** : Partitionnement des données sur plusieurs serveurs pour la scalabilité.
- **Replica Set** : Groupe de serveurs MongoDB qui maintiennent les mêmes données pour la redondance et la disponibilité[1][3].

## 💻 Requêtes/Commandes de Base

```javascript
// Afficher les bases de données
show dbs

// Sélectionner ou créer une base de données
use maBaseDeDonnees

// Afficher les collections
show collections

// Insérer un document
db.maCollection.insertOne({ champ: "valeur" })

// Insérer plusieurs documents
db.maCollection.insertMany([{ champ1: "valeur1" }, { champ2: "valeur2" }])

// Rechercher des documents
db.maCollection.find({ champ: "valeur" })

// Mettre à jour un document
db.maCollection.updateOne({ champ: "valeur" }, { $set: { champ: "nouvelleValeur" } })

// Supprimer un document
db.maCollection.deleteOne({ champ: "valeur" })
```


## 📊 Tableau Comparatif : MongoDB vs RDBMS

| Critère            | RDBMS (SQL)           | MongoDB (NoSQL)         |
|--------------------|-----------------------|-------------------------|
| Schéma             | Fixe                  | Flexible                |
| Transactions       | Multi-tables ACID     | Multi-documents limité  |
| Scalabilité        | Verticale             | Horizontale (sharding)  |
| Requêtes           | SQL                   | Query langage spécifique|
| Stockage           | Tables                | Collections/Documents   |
| Indexation         | Oui                   | Oui                     |

[3]

## 📈 Exemple de Modélisation

```javascript
{
  title: "Post Title 1",
  body: "Body of post.",
  category: "News",
  likes: 1,
  tags: ["news", "events"],
  date: Date()
}
```


## ⚠️ Points de vigilance

- **Sécurité** : Configuration obligatoire de l’authentification, des rôles et des pare-feux pour protéger les accès.
- **Sauvegarde/Restauration** : Mettre en place des procédures régulières de sauvegarde, surtout en production.
- **Gestion des droits** : Limiter les privilèges des utilisateurs selon le principe du moindre privilège.
- **Volumétrie** : Surveiller la croissance des données et anticiper le besoin de sharding ou d’optimisation[4][3].

## 🛠️ Outils Recommandés

- **MongoDB Shell** : Interface en ligne de commande pour interagir avec la base.
- **MongoDB Compass** : Interface graphique pour explorer et gérer les données.
- **MongoDB Atlas** : Solution cloud gérée pour déployer, surveiller et sauvegarder vos bases.
- **Mongoose (Node.js)** : ODM pour faciliter la modélisation et la validation des données[2].

## 🔗 Ressources Utiles

- **Documentation officielle MongoDB** : Référence complète pour tous les concepts et fonctionnalités[5][4].
- **Tutoriels et exemples** : Nombreux exemples et guides pratiques disponibles en ligne[6][1].
- **Communauté et forums** : Support actif et échanges avec d’autres utilisateurs[5].

Cette page synthétise l’essentiel de la documentation générale MongoDB, adaptée à un usage professionnel et pédagogique. Pour aller plus loin, consultez la documentation officielle ou explorez les exemples de code et de configuration disponibles dans les dépôts référencés.

[1] https://www.w3schools.com/mongodb/

[2] https://github.com/learnwithfair/mongodb-documentation/blob/main/README.md

[3] https://github.com/martimdLima/mongodb-the-complete-developers-guide

[4] https://www.mongodb.com/docs/manual/tutorial/

[5] https://www.mongodb.com/docs/

[6] https://github.com/jmrenouard/mongodb-training/tree/main/documentation/

[7] https://www.mongodb.com/docs/manual/tutorial/getting-started/

[8] https://www.mongodb.com/docs/manual/introduction/

[9] https://www.mongodb.com/developer/languages/javascript/getting-started-with-mongodb-and-mongoose/

[10] https://github.com/PacktPublishing/MongoDB---The-Complete-Developer-s-Guide-/blob/master/README.md

[11] https://github.com/manthanank/learn-mongodb/blob/main/README.md