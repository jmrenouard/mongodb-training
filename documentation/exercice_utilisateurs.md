Voici une procédure détaillée pour la gestion des rôles sous MongoDB, incluant la création de différents types de comptes d’utilisateurs et le changement de mot de passe.

## 🏗️ Procédure de Création des Comptes Utilisateurs MongoDB

### 1. **Création d’un Super Administrateur**

Un super administrateur a tous les droits sur toutes les bases de données.

```javascript
use admin
db.createUser(
  {
    user: "superadmin",
    pwd: "motdepasseSuperAdmin", // À remplacer par un mot de passe fort
    roles: [ "root" ]
  }
)
```

**Explication** :  
Le rôle `root` donne tous les privilèges sur toutes les bases de données.

### 2. **Création d’un Administrateur de Base de Données**

Ce compte peut gérer les collections, lire et écrire dans la base, mais pas administrer d’autres bases ou le serveur.

```javascript
use maBase
db.createUser(
  {
    user: "adminDB",
    pwd: "motdepasseAdminDB", // À remplacer
    roles: [
      { role: "dbAdmin", db: "maBase" },
      { role: "readWrite", db: "maBase" }
    ]
  }
)
```

**Explication** :  
- **dbAdmin** : gestion des collections (index, statistiques, etc.).
- **readWrite** : lecture et écriture sur la base.

### 3. **Création d’un Compte Lecture Seule**

Ce compte peut uniquement lire les données.

```javascript
use maBase
db.createUser(
  {
    user: "lecture",
    pwd: "motdepasseLecture", // À remplacer
    roles: [ { role: "read", db: "maBase" } ]
  }
)
```

### 4. **Création d’un Compte Lecture/Écriture/Suppression**

Ce compte peut lire, écrire et supprimer des documents.

```javascript
use maBase
db.createUser(
  {
    user: "lectureEcritureSuppression",
    pwd: "motdepasseLEC", // À remplacer
    roles: [ { role: "readWrite", db: "maBase" } ]
  }
)
```

**Remarque** :  
Le rôle `readWrite` permet déjà la suppression, car il inclut toutes les opérations de modification (insert, update, delete).

## 🔄 Procédure de Changement de Mot de Passe

Pour changer le mot de passe d’un utilisateur :

```javascript
use admin
db.changeUserPassword("nomUtilisateur", "nouveauMotDePasse")
```

**Exemple pour le superadmin** :
```javascript
use admin
db.changeUserPassword("superadmin", "nouveauMotDePasseSuperAdmin")
```

## 📊 Tableau Récapitulatif des Rôles

| Rôle/Compte                         | Droits Principaux                                      |
|--------------------------------------|--------------------------------------------------------|
| Super Administrateur (`root`)        | Tous droits sur toutes les bases                       |
| Administrateur DB (`dbAdmin`, `readWrite`) | Gestion collections, lecture/écriture sur la base |
| Lecture seule (`read`)               | Lecture des données                                    |
| Lecture/Écriture/Suppression (`readWrite`) | Lecture, écriture, suppression des documents     |

## ⚠️ Points de Vigilance

- **Mot de passe fort** : Utilisez toujours des mots de passe complexes pour chaque compte.
- **Minimisation des privilèges** : Accordez uniquement les droits nécessaires à chaque utilisateur.
- **Audit régulier** : Vérifiez régulièrement les comptes et leurs rôles pour éviter les accès indésirables.
- **Sécurité du mot de passe** : Ne stockez jamais les mots de passe en clair, et utilisez le chiffrement réseau (TLS/SSL) pour toutes les connexions.

## 💻 Exemple d’Utilisation

Après création, connectez-vous avec le compte souhaité :
```bash
mongo --username superadmin --password motdepasseSuperAdmin --authenticationDatabase admin
```

Cette procédure vous permet de gérer efficacement les accès et la sécurité de votre base MongoDB.