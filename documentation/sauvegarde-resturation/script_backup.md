# **Script de Sauvegarde Logique MongoDB (mongodump)**

Ce dépôt contient un script Bash robuste (mongodb\_backup.sh) conçu pour automatiser les sauvegardes logiques de vos bases de données MongoDB. Il prend en charge diverses topologies (standalone, replica set, sharded cluster) et offre des fonctionnalités essentielles telles que la compression, la vérification d'intégrité via SHA256, et l'encryption optionnelle des sauvegardes.

## **Table des Matières**

* [Fonctionnalités](https://www.google.com/search?q=%23fonctionnalit%C3%A9s)  
* [Avertissement de Sécurité](https://www.google.com/search?q=%23avertissement-de-s%C3%A9curit%C3%A9)  
* [Prérequis](https://www.google.com/search?q=%23pr%C3%A9requis)  
* [Utilisation](https://www.google.com/search?q=%23utilisation)  
  * [Syntaxe Générale](https://www.google.com/search?q=%23syntaxe-g%C3%A9n%C3%A9rale)  
  * [Exemples d'Utilisation](https://www.google.com/search?q=%23exemples-dutilisation)  
* [Détails Techniques](https://www.google.com/search?q=%23d%C3%A9tails-techniques)  
* [Restauration](https://www.google.com/search?q=%23restauration)  
* [Planification et Maintenance](https://www.google.com/search?q=%23planification-et-maintenance)

## **Fonctionnalités**

* **Prise en charge Multi-Topologie** : Sauvegarde des instances MongoDB standalone, des replica sets et des clusters shardés.  
* **Détection du Primaire** : Pour les replica sets, le script identifie automatiquement le nœud primaire pour garantir une sauvegarde cohérente.  
* **Sauvegarde Cohérente** : Utilise l'option \--oplog de mongodump pour les replica sets et les clusters shardés, permettant des restaurations point-in-time.  
* **Compression Automatique** : Compresse le répertoire de sauvegarde en un fichier .tar.gz.  
* **Vérification d'Intégrité** : Génère une somme de contrôle SHA256 pour le fichier compressé, permettant de vérifier son intégrité après le transfert ou le stockage.  
* **Encryption Optionnelle** : Permet d'encrypter le fichier de sauvegarde compressé avec un mot de passe via openssl pour une sécurité accrue.  
* **Journalisation** : Tous les messages du script sont enregistrés dans un fichier de log dédié (/var/backups/mongodb/mongodb\_backup.log) et affichés sur la console.  
* **Gestion des Répertoires** : Vérifie et crée automatiquement le répertoire de base des sauvegardes (/var/backups/mongodb/) si nécessaire.

## **Avertissement de Sécurité**

Il est fortement déconseillé de stocker des mots de passe en clair directement dans des scripts pour les environnements de production.  
Ce script accepte les identifiants MongoDB et le mot de passe d'encryption en tant que paramètres pour des raisons de commodité (développement, test). Pour un usage en production, veuillez envisager des méthodes plus sécurisées :

* **Variables d'environnement** : Définissez MONGO\_USERNAME, MONGO\_PASSWORD, MONGO\_AUTHENTICATION\_DATABASE, MONGO\_ENCRYPTION\_PASSWORD.  
* **Fichiers de clés** : Pour l'authentification inter-serveurs dans MongoDB.  
* **Gestionnaires de secrets** : Des outils dédiés à la gestion sécurisée des secrets (ex: HashiCorp Vault, AWS Secrets Manager, Google Secret Manager).

## **Prérequis**

* **Système d'exploitation** : Compatible avec les systèmes basés sur Debian/Ubuntu (Ubuntu 24.04 recommandé).  
* **Outils MongoDB** :  
  * mongodump  
  * mongosh (nécessaire pour la détection du primaire dans les replica sets)  
* **Outils Système** :  
  * tar  
  * gzip  
  * sha256sum  
  * openssl (pour l'encryption)  
* **Permissions** :  
  * L'utilisateur exécutant le script doit avoir les permissions de lecture/écriture sur le répertoire de sauvegarde (/var/backups/mongodb/).  
  * L'utilisateur MongoDB utilisé pour la sauvegarde doit avoir les rôles backup ou read sur les bases de données à sauvegarder.  
  * Pour les replica sets et les clusters shardés, l'utilisateur MongoDB doit également avoir le rôle clusterMonitor pour permettre au script de trouver le primaire ou de se connecter au mongos.

## **Utilisation**

1. **Téléchargez le script** :  
   wget \-O mongodb\_backup.sh https://raw.githubusercontent.com/votre\_utilisateur/votre\_repo/main/mongodb\_backup.sh \# Remplacez par votre URL réelle

2. **Rendez-le exécutable** :  
   chmod \+x mongodb\_backup.sh

3. **Exécutez le script** en fonction de votre topologie MongoDB et de vos besoins en encryption.

### **Syntaxe Générale**

bash ./mongodb\_backup.sh \<TYPE\_DE\_SAUVEGARDE\> \<HOST\> \<PORT\> \[USERNAME\] \[PASSWORD\] \[AUTH\_DB\] \[ENCRYPTION\_PASSWORD\]

* \<TYPE\_DE\_SAUVEGARDE\> : standalone, replicaset, ou sharded.  
* \<HOST\> : Adresse IP ou nom d'hôte de l'instance MongoDB (ou d'un membre du replica set, ou du mongos).  
* \<PORT\> : Port de l'instance MongoDB.  
* \[USERNAME\] : (Optionnel) Nom d'utilisateur MongoDB.  
* \[PASSWORD\] : (Optionnel) Mot de passe de l'utilisateur MongoDB.  
* \[AUTH\_DB\] : (Optionnel, par défaut admin) Base de données d'authentification de l'utilisateur MongoDB.  
* \[ENCRYPTION\_PASSWORD\] : (Optionnel) Mot de passe pour encrypter le fichier de sauvegarde. Si fourni, le fichier .tar.gz sera encrypté en .tar.gz.enc.

### **Exemples d'Utilisation**

#### **1\. Sauvegarde d'une instance Standalone**

* **Sans authentification, sans encryption :**  
  bash ./mongodb\_backup.sh standalone localhost 27017

* **Avec authentification, sans encryption :**  
  bash ./mongodb\_backup.sh standalone localhost 27017 myuser mypassword admin

* **Avec authentification et encryption :**  
  bash ./mongodb\_backup.sh standalone localhost 27017 myuser mypassword admin mySuperSecretEncryptionKey

#### **2\. Sauvegarde d'un Replica Set**

Le script se connectera à l'hôte/port fourni pour trouver le nœud primaire et effectuera la sauvegarde à partir de celui-ci.

* **Avec authentification, sans encryption :**  
  bash ./mongodb\_backup.sh replicaset rs0-member1.example.com 27017 backupUser backupPass admin

* **Avec authentification et encryption :**  
  bash ./mongodb\_backup.sh replicaset rs0-member1.example.com 27017 backupUser backupPass admin myReplicaSetEncryptionKey

#### **3\. Sauvegarde d'un Sharded Cluster**

La sauvegarde doit être effectuée via une instance mongos.

* **Avec authentification, sans encryption :**  
  bash ./mongodb\_backup.sh sharded my-mongos.example.com 27020 adminUser adminPass admin

* **Avec authentification et encryption :**  
  bash ./mongodb\_backup.sh sharded my-mongos.example.com 27020 adminUser adminPass admin myShardedClusterEncryptionKey

## **Détails Techniques**

* **find\_primary Function** : Cette fonction interne utilise mongosh pour interroger le statut du replica set (rs.isMaster()) et extraire l'adresse du nœud primaire. Cela garantit que mongodump se connecte toujours à la source de données la plus à jour et la plus cohérente dans un replica set.  
* **\--oplog Option** : Pour les replica sets et les clusters shardés, l'option \--oplog est ajoutée à mongodump. Cela inclut le journal des opérations (oplog) dans la sauvegarde, ce qui est crucial pour les restaurations point-in-time et pour maintenir la cohérence des données dans les environnements distribués.

## **Restauration**

Pour restaurer une sauvegarde effectuée avec ce script :

1. **Déchiffrer le fichier (si encrypté)** :  
   openssl enc \-aes-256-cbc \-d \-in "/path/to/backup\_file.tar.gz.enc" \-out "/path/to/backup\_file.tar.gz" \-k "YOUR\_ENCRYPTION\_PASSWORD"

2. **Décompresser le fichier** :  
   tar \-xzf "/path/to/backup\_file.tar.gz" \-C "/your/restore/directory"

   Cela extraira le contenu de la sauvegarde (un répertoire nommé avec l'horodatage) dans le répertoire de restauration spécifié.  
3. **Restaurer avec mongorestore** :  
   mongorestore \--host \<TARGET\_HOST\> \--port \<TARGET\_PORT\> \--username \<USERNAME\> \--password \<PASSWORD\> \--authenticationDatabase \<AUTH\_DB\> \--oplogReplay "/your/restore/directory/backup\_data\_timestamp"

   * \--oplogReplay est essentiel si la sauvegarde a été faite avec \--oplog.

## **Planification et Maintenance**

* **Cron Jobs** : Intégrez ce script dans un job cron pour automatiser les sauvegardes régulières (quotidiennes, hebdomadaires, etc.).  
* **Politique de Rétention** : Mettez en place un script distinct pour supprimer les anciennes sauvegardes et gérer l'espace disque.  
* **Surveillance** : Surveillez les logs du script (/var/backups/mongodb/mongodb\_backup.log) et les logs de MongoDB pour détecter toute anomalie ou échec de sauvegarde.  
* **Stockage Externe** : Envisagez de déplacer les fichiers de sauvegarde vers un stockage externe ou un service de stockage cloud (ex: S3, Google Cloud Storage, NFS) pour une meilleure résilience en cas de défaillance du serveur.