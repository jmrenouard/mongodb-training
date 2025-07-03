Voici un tableau synthétique des principaux rôles prédéfinis dans MongoDB, avec leur portée et leur description.

| Catégorie de rôle                  | Nom du rôle            | Portée/Base de données         | Description                                                                                      |
|-------------------------------------|------------------------|-------------------------------|--------------------------------------------------------------------------------------------------|
| **Rôles d’utilisateur**             | read                   | Toute base                    | Lecture sur toutes les collections non-système et la collection `system.js`[1][2][3].            |
|                                     | readWrite              | Toute base                    | Lecture et écriture sur toutes les collections non-système et `system.js`[1][2][3].              |
| **Rôles d’administration base**     | dbAdmin                | Toute base                    | Tâches administratives (index, statistiques), sans gestion des utilisateurs/roles[1][2][3].      |
|                                     | userAdmin              | Toute base                    | Création et modification d’utilisateurs/roles sur la base courante[1][2][3].                     |
|                                     | dbOwner                | Toute base                    | Toutes les actions sur la base (équivaut à readWrite + dbAdmin + userAdmin)[1][2][3].            |
| **Rôles d’administration cluster**  | clusterManager         | admin                         | Gestion/monitoring du cluster (sharding, réplication)[2][3].                                     |
|                                     | clusterMonitor         | admin                         | Accès en lecture aux outils de monitoring du cluster[2][3].                                      |
|                                     | hostManager            | admin                         | Surveillance et gestion des serveurs individuels[2][3].                                          |
|                                     | clusterAdmin           | admin                         | Toutes les actions d’administration du cluster (équivaut à clusterManager + clusterMonitor + hostManager + dropDatabase)[2][3]. |
| **Rôles de backup/restauration**    | backup                 | admin                         | Privilèges nécessaires pour sauvegarder les données[2][3].                                       |
|                                     | restore                | admin                         | Privilèges nécessaires pour restaurer les données[2][3].                                         |
| **Rôles toutes bases**              | readAnyDatabase        | admin                         | Lecture sur toutes les bases de données[2][3].                                                   |
|                                     | readWriteAnyDatabase   | admin                         | Lecture/écriture sur toutes les bases de données[2][3].                                          |
|                                     | userAdminAnyDatabase   | admin                         | Création/modification d’utilisateurs/roles sur toutes les bases de données[2][3].                |
|                                     | dbAdminAnyDatabase     | admin                         | Tâches administratives sur toutes les bases de données[2][3].                                    |
| **Rôles superutilisateur**          | root                   | admin                         | Accès complet à toutes les ressources et opérations du cluster (superuser)[1][2][3].             |
| **Rôle interne**                    | __system               | admin                         | Réservé aux membres du cluster (replica set, mongos). Ne jamais l’attribuer à un utilisateur[1]. |

## ⚠️ Points de vigilance

- **Attribution des rôles superutilisateurs** : Les rôles comme `root`, `userAdmin`, `dbOwner` (sur admin), `userAdminAnyDatabase` permettent d’attribuer n’importe quel privilège, y compris à soi-même. Ils doivent être attribués avec la plus grande prudence pour éviter des risques d’élévation de privilèges et de compromission de la sécurité[1][2][3].
- **Rôle __system** : Réservé aux processus internes de MongoDB. Ne jamais l’attribuer à un utilisateur applicatif ou humain, sauf cas exceptionnel, pour éviter des risques de sécurité majeurs[1].

## Exemple d’attribution de rôle

Pour attribuer un rôle à un utilisateur lors de sa création :

```javascript
db.createUser({
  user: "utilisateur1",
  pwd: "motdepasse",
  roles: [
    { role: "readWrite", db: "maBase" }
  ]
})
```
ou pour attribuer plusieurs rôles :

```javascript
db.createUser({
  user: "admin1",
  pwd: "motdepasse",
  roles: [
    { role: "dbOwner", db: "maBase" },
    { role: "readAnyDatabase", db: "admin" }
  ]
})
```

[1] https://www.mongodb.com/docs/manual/reference/built-in-roles/
[2] https://www.bmc.com/blogs/mongodb-role-based-access-control/
[3] https://studio3t.com/knowledge-base/articles/mongodb-users-roles-explained-part-1/
[4] https://github.com/mongodb/docs/blob/master/source/reference/built-in-roles.txt
[5] https://docs.byteplus.com/en/docs/mongodb/account-and-permission
[6] https://www.mongodb.com/docs/manual/tutorial/manage-users-and-roles/
[7] https://mongoing.com/docs/core/security-built-in-roles.html
[8] https://www.mongodb.com/docs/atlas/reference/user-roles/
[9] https://docs.huihoo.com/mongodb/3.4/reference/built-in-roles/index.html
[10] https://www.mongodb.com/docs/manual/core/authorization/