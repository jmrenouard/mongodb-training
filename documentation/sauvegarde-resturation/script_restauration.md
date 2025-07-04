# **Script de Restauration Logique MongoDB (mongorestore)**

Ce dépôt contient un script Bash robuste (mongodb\_restore.sh) conçu pour automatiser la restauration de vos bases de données MongoDB à partir de sauvegardes logiques créées avec mongodump (notamment celles générées par le script mongodb\_backup.sh). Il gère le déchiffrement, la décompression et l'exécution de mongorestore avec les options appropriées.

## **Table des Matières**

* [Fonctionnalités](https://www.google.com/search?q=%23fonctionnalit%C3%A9s)  
* [Avertissement de Sécurité](https://www.google.com/search?q=%23avertissement-de-s%C3%A9curit%C3%A9)  
* [Prérequis](https://www.google.com/search?q=%23pr%C3%A9requis)  
* [Utilisation](https://www.google.com/search?q=%23utilisation)  
  * [Syntaxe Générale](https://www.google.com/search?q=%23syntaxe-g%C3%A9n%C3%A9rale)  
  * [Exemples d'Utilisation](https://www.google.com/search?q=%23exemples-dutilisation)  
* [Détails Techniques](https://www.google.com/search?q=%23d%C3%A9tails-techniques)  
* [Considérations Importantes pour la Restauration](https://www.google.com/search?q=%23consid%C3%A9rations-importantes-pour-la-restauration)

## **Fonctionnalités**

* **Gestion des Fichiers de Sauvegarde** : Prend en charge les fichiers de sauvegarde compressés (.tar.gz) et encryptés (.tar.gz.enc).  
* **Déchiffrement Automatique** : Si le fichier de sauvegarde est encrypté, le script le déchiffre automatiquement à l'aide du mot de passe fourni.  
* **Décompression Automatique** : Décompresse l'archive de sauvegarde dans un répertoire temporaire.  
* **Restauration Intelligente** : Détecte si la sauvegarde a été faite avec l'oplog (pour les replica sets ou les clusters shardés) et utilise automatiquement l'option \--oplogReplay de mongorestore pour garantir la cohérence des données.  
* **Option \--drop** : Permet de supprimer les collections existantes dans la base de données cible avant la restauration (à utiliser avec prudence).  
* **Nettoyage Automatique** : Supprime les fichiers temporaires et les répertoires créés pendant le processus de restauration.  
* **Journalisation** : Tous les messages du script sont enregistrés dans un fichier de log dédié (/var/log/mongodb/mongodb\_restore.log) et affichés sur la console.

## **Avertissement de Sécurité**

Il est fortement déconseillé de stocker des mots de passe en clair directement dans des scripts pour les environnements de production.  
Ce script accepte les identifiants MongoDB et le mot de passe d'encryption en tant que paramètres pour des raisons de commodité (développement, test). Pour un usage en production, veuillez envisager des méthodes plus sécurisées :

* **Variables d'environnement** : Définissez MONGO\_USERNAME, MONGO\_PASSWORD, MONGO\_AUTHENTICATION\_DATABASE, MONGO\_ENCRYPTION\_PASSWORD.  
* **Gestionnaires de secrets** : Des outils dédiés à la gestion sécurisée des secrets (ex: HashiCorp Vault, AWS Secrets Manager, Google Secret Manager).

## **Prérequis**

* **Système d'exploitation** : Compatible avec les systèmes basés sur Debian/Ubuntu (Ubuntu 24.04 recommandé).  
* **Outils MongoDB** :  
  * mongorestore  
* **Outils Système** :  
  * tar  
  * gzip  
  * openssl (si vous utilisez des sauvegardes encryptées)  
* **Permissions** :  
  * L'utilisateur exécutant le script doit avoir les permissions de lecture sur le fichier de sauvegarde et les permissions de lecture/écriture sur le répertoire temporaire (/tmp/).  
  * L'utilisateur MongoDB utilisé pour la restauration doit avoir les rôles restore ou dbAdminAnyDatabase / root sur les bases de données cibles.

## **Utilisation**

1. **Téléchargez le script** :  
   wget \-O mongodb\_restore.sh https://raw.githubusercontent.com/votre\_utilisateur/votre\_repo/main/mongodb\_restore.sh \# Remplacez par votre URL réelle

2. **Rendez-le exécutable** :  
   chmod \+x mongodb\_restore.sh

3. **Exécutez le script** avec les arguments appropriés.

### **Syntaxe Générale**

bash ./mongodb\_restore.sh \<FICHIER\_DE\_SAUVEGARDE\> \<HOST\_CIBLE\> \<PORT\_CIBLE\> \[USERNAME\] \[PASSWORD\] \[AUTH\_DB\] \[ENCRYPTION\_PASSWORD\] \[--drop\]

* **\<FICHIER\_DE\_SAUVEGARDE\>** : Chemin complet vers le fichier .tar.gz ou .tar.gz.enc de la sauvegarde.  
* **\<HOST\_CIBLE\>** : L'adresse IP ou le nom d'hôte de l'instance MongoDB où restaurer les données.  
  * Pour un **replica set**, ce doit être le **primaire** actuel.  
  * Pour un **sharded cluster**, ce doit être une instance **mongos**.  
* **\<PORT\_CIBLE\>** : Le port de l'instance MongoDB cible.  
* \[USERNAME\] : (Optionnel) Nom d'utilisateur MongoDB pour la restauration.  
* \[PASSWORD\] : (Optionnel) Mot de passe de l'utilisateur MongoDB.  
* \[AUTH\_DB\] : (Optionnel, par défaut admin) Base de données d'authentification de l'utilisateur.  
* \[ENCRYPTION\_PASSWORD\] : (Optionnel) Mot de passe utilisé pour encrypter la sauvegarde. Requis si le fichier se termine par .enc.  
* \[--drop\] : (Optionnel) Si présent, supprime les collections existantes dans les bases de données cibles avant la restauration. **Utilisez cette option avec une extrême prudence car elle peut entraîner une perte de données irréversible.**

### **Exemples d'Utilisation**

#### **1\. Restaurer une sauvegarde Standalone (non encryptée)**

bash ./mongodb\_restore.sh /var/backups/mongodb/standalone\_localhost\_27017\_20250704\_160000.tar.gz localhost 27017 admin myRestorePass admin

#### **2\. Restaurer une sauvegarde Replica Set (encryptée, avec \--drop)**

bash ./mongodb\_restore.sh /var/backups/mongodb/replicaset\_rs0member1.example.com\_27017\_20250704\_160000.tar.gz.enc rs0-primary.example.com 27017 admin myRestorePass admin myEncryptionKey \--drop

#### **3\. Restaurer une sauvegarde Sharded Cluster (non encryptée)**

bash ./mongodb\_restore.sh /var/backups/mongodb/sharded\_mongos1.example.com\_27020\_20250704\_160000.tar.gz mongos.example.com 27020 admin myRestorePass admin

## **Détails Techniques**

* **Détection \--oplogReplay** : Le script analyse le nom du fichier de sauvegarde (qui contient le type de topologie grâce au script de sauvegarde) pour déterminer si l'option \--oplogReplay doit être utilisée avec mongorestore. Cette option est cruciale pour garantir la cohérence des données lors de la restauration de sauvegardes provenant de replica sets ou de clusters shardés.  
* **Répertoire Temporaire** : Un répertoire unique est créé dans /tmp/ pour décompresser la sauvegarde. Ce répertoire est automatiquement nettoyé à la fin du processus.  
* **Gestion des Erreurs** : Le script inclut des vérifications à chaque étape et sort avec un code d'erreur si une opération échoue, fournissant des messages clairs pour faciliter le débogage.

## **Considérations Importantes pour la Restauration**

* **Identifiants de Restauration** : L'utilisateur MongoDB utilisé pour la restauration doit avoir les privilèges suffisants pour écrire des données dans les bases de données cibles et, si nécessaire, gérer les utilisateurs ou les rôles.  
* **Cible de Restauration** : Assurez-vous de restaurer vers le bon type de nœud : le primaire pour un replica set, ou un mongos pour un cluster shardé.  
* **Espace Disque Temporaire** : Le répertoire temporaire (/tmp/ par défaut) doit disposer de suffisamment d'espace disque pour contenir la sauvegarde décompressée.  
* **Validation Post-Restauration** : Après la restauration, il est **crucial** de vérifier l'intégrité et la complétude des données dans votre instance MongoDB. Exécutez des requêtes de validation, vérifiez les comptes de documents, etc.  
* **Impact sur la Production** : La restauration peut être une opération gourmande en ressources et peut impacter les performances de votre base de données. Planifiez les restaurations pendant les périodes de faible activité.