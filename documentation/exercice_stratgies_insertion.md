L’insertion de documents JSON dans MongoDB se fait de plusieurs manières, adaptées à différents contextes : depuis la ligne de commande, via des scripts, ou à l’aide d’outils spécialisés. Voici les principales méthodes :

## 🧩 Insertion via MongoDB Shell

### Insertion unique (`insertOne`)
Pour insérer un seul document JSON :
```javascript
db.nomCollection.insertOne({
  "nom": "Alice",
  "age": 28,
  "ville": "Paris"
});
```
Cette méthode insère un document unique dans la collection spécifiée[1][2].

### Insertion multiple (`insertMany`)
Pour insérer plusieurs documents JSON à la fois :
```javascript
db.nomCollection.insertMany([
  { "nom": "Bob", "age": 32, "ville": "Lyon" },
  { "nom": "Claire", "age": 29, "ville": "Marseille" }
]);
```
Cette méthode permet d’insérer un tableau de documents en une seule opération[1][2].

## 🛠️ Insertion via outils CLI (`mongoimport`)

Pour importer un fichier JSON contenant des documents dans une collection MongoDB :
```bash
mongoimport --db nomBase --collection nomCollection --file chemin/vers/fichier.json
```
Si le fichier contient un tableau de documents, utilisez l’option `--jsonArray` :
```bash
mongoimport --db nomBase --collection nomCollection --file chemin/vers/fichier.json --jsonArray
```
Cet outil est particulièrement adapté pour l’import massif de données à partir de fichiers JSON[3].

## 📄 Exemple d’utilisation dans une application (Node.js)

Avec le pilote MongoDB pour Node.js, l’insertion s’effectue ainsi :
```javascript
const MongoClient = require('mongodb').MongoClient;
const uri = "mongodb://localhost:27017/";
const client = new MongoClient(uri, { useNewUrlParser: true, useUnifiedTopology: true });

async function insertDocuments() {
  try {
    await client.connect();
    const db = client.db("nomBase");
    const collection = db.collection("nomCollection");
    const result = await collection.insertMany([
      { "nom": "David", "age": 25 },
      { "nom": "Eva", "age": 30 }
    ]);
    console.log(`${result.insertedCount} documents insérés`);
  } finally {
    await client.close();
  }
}
insertDocuments();
```

## ⚠️ Points de vigilance

- **Format du fichier JSON** : Assurez-vous que le fichier respecte la syntaxe JSON valide. Un fichier contenant un tableau de documents nécessite l’option `--jsonArray` avec `mongoimport`.
- **Clé `_id`** : Si elle n’est pas spécifiée, MongoDB génère automatiquement un identifiant unique.
- **Sécurité** : Limitez l’accès aux outils d’import/export pour éviter des fuites ou des corruptions de données.

## 🏁 Résumé

- **Insertion unique** : `insertOne`
- **Insertion multiple** : `insertMany`
- **Import depuis fichier** : `mongoimport`
- **Insertion via application** : Utilisation du pilote MongoDB adapté au langage (ex : Node.js, Python, etc.)

Ces méthodes couvrent la plupart des besoins d’insertion de documents JSON dans MongoDB[1][3][2].

[1] https://sparkbyexamples.com/mongodb/mongodb-insertone-insertmany-documents/

[2] https://stph.scenari-community.org/bdd/nos2/co/insert.html

[3] https://sparkbyexamples.com/mongodb/import-json-file-using-the-mongoimport-command/

[4] https://forum.alsacreations.com/topic-5-89445-1-Resolu-Inserer-le-contenu-dun-fichier-json-dans-mongo-db.html

[5] https://stph.scenari-community.org/idl-bd/idl-nosql/co/insert.html

[6] https://www.mongodb.com/resources/languages/json-to-mongodb

[7] https://www.developpez.net/forums/d1506938/bases-donnees/nosql/importer-fichiers-json-mongo-db/

[8] https://www.youtube.com/watch?v=Xd3k92DyrTU

[9] https://stackoverflow.com/questions/77132884/insert-many-json-file-inside-one-document-in-mongodb

[10] https://www.editions-eni.fr/livre/mongodb-comprendre-et-optimiser-l-exploitation-de-vos-donnees-avec-exercices-et-corriges-2e-edition-9782409046407/importer-exporter-et-restaurer-des-donnees