Voici une procédure structurée pour tester et valider la configuration système Linux (Ubuntu) dans le contexte d’une installation MongoDB, incluant les étapes, types de tests, commandes de vérification et remédiation.

## ✅ Procédure de Test des Configurations Système Linux pour MongoDB (Ubuntu)

### 1. Vérification de la Version et de la Mise à Jour du Système

**Type** : Configuration système  
**Commande de vérification** :
```bash
lsb_release -a
```
> Permet de vérifier la version d’Ubuntu installée[1].

**Remédiation** :  
Si la version n’est pas à jour ou si des mises à jour sont disponibles :
```bash
sudo apt update && sudo apt upgrade -y
```
> Met à jour tous les paquets et corrige les failles de sécurité potentielles[2][3].

### 2. Installation et Configuration du Référentiel MongoDB

**Type** : Configuration logicielle  
**Commande de vérification** :
```bash
cat /etc/apt/sources.list.d/mongodb-org-*.list
```
> Vérifie la présence du référentiel MongoDB officiel.

**Remédiation** :  
Si le référentiel n’est pas présent :
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
```
> Ajoute le référentiel MongoDB et met à jour les index de paquets[2][4].

### 3. Installation de MongoDB

**Type** : Installation logicielle  
**Commande de vérification** :
```bash
dpkg -l | grep mongodb-org
```
> Vérifie que MongoDB est installé.

**Remédiation** :  
Si MongoDB n’est pas installé :
```bash
sudo apt install -y mongodb-org
```
> Installe le paquet MongoDB[5][3][4].

### 4. Démarrage et Activation du Service MongoDB

**Type** : Gestion des services  
**Commande de vérification** :
```bash
sudo systemctl status mongod
```
> Vérifie l’état du service MongoDB[5][1][3].

**Remédiation** :  
Si le service n’est pas actif :
```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```
> Démarre et active le service MongoDB au démarrage[5][3][4].

### 5. Vérification de la Version de MongoDB

**Type** : Vérification logicielle  
**Commande de vérification** :
```bash
mongod --version
```
> Affiche la version installée de MongoDB[1][3][4].

### 6. Test de Fonctionnement et de Connectivité

**Type** : Test d’intégration  
**Commande de vérification** :
```bash
mongosh
```
> Lance le shell MongoDB pour vérifier la connectivité.

À l’intérieur du shell :
```javascript
db.runCommand({ connectionStatus: 1 })
```
> Vérifie la connexion au serveur MongoDB[3].

**Remédiation** :  
Si la connexion échoue, vérifiez les logs MongoDB :
```bash
tail -f /var/log/mongodb/mongod.log
```
> Analyse les logs pour identifier les erreurs[6].

### 7. Vérification du Port d’Écoute

**Type** : Configuration réseau  
**Commande de vérification** :
```bash
ss -pnltu | grep 27017
```
> Vérifie que MongoDB écoute sur le port 27017[4].

**Remédiation** :  
Si le port n’est pas ouvert, vérifiez la configuration dans `/etc/mongod.conf` et redémarrez le service :
```bash
sudo systemctl restart mongod
```
> Applique les modifications de configuration[6].

### 8. Sécurisation de MongoDB

**Type** : Sécurité  
**Commande de vérification** :
```bash
grep -E "security|authorization" /etc/mongod.conf
```
> Vérifie la présence de directives de sécurité dans la configuration.

**Remédiation** :  
Ajoutez ou modifiez dans `/etc/mongod.conf` :
```yaml
security:
  authorization: enabled
```
> Active l’authentification pour sécuriser l’accès à la base de données[2][6].

Redémarrez ensuite le service :
```bash
sudo systemctl restart mongod
```

## 📊 Tableau Récapitulatif

| Étape                         | Type                  | Commande de vérification                   | Commande de remédiation                      |
|-------------------------------|-----------------------|--------------------------------------------|----------------------------------------------|
| Version système               | Configuration         | `lsb_release -a`                           | `sudo apt update && sudo apt upgrade -y`     |
| Référentiel MongoDB           | Configuration         | `cat /etc/apt/sources.list.d/mongodb-org-*.list` | Ajout du référentiel (voir ci-dessus)         |
| Installation MongoDB          | Installation          | `dpkg -l \| grep mongodb-org`              | `sudo apt install -y mongodb-org`            |
| Démarrage service             | Gestion des services  | `sudo systemctl status mongod`             | `sudo systemctl start mongod`                |
| Activation au démarrage       | Gestion des services  | `sudo systemctl is-enabled mongod`         | `sudo systemctl enable mongod`               |
| Version MongoDB               | Vérification          | `mongod --version`                         | -                                            |
| Test connectivité             | Test d’intégration    | `mongosh` puis `db.runCommand({ connectionStatus: 1 })` | Analyse logs `/var/log/mongodb/mongod.log`   |
| Port d’écoute                 | Réseau                | `ss -pnltu \| grep 27017`                  | Modifiez `/etc/mongod.conf` et redémarrez    |
| Sécurisation MongoDB          | Sécurité              | `grep -E "security\|authorization" /etc/mongod.conf` | Ajoutez `security: authorization: enabled`   |

## ⚠️ Points de vigilance

- **Sécurité** : Ne laissez jamais MongoDB accessible sans authentification en production. Configurez toujours l’authentification et limitez l’accès au port 27017.
- **Compatibilité** : Assurez-vous que la version d’Ubuntu et celle de MongoDB sont compatibles.
- **Continuité de service** : Vérifiez que le service est bien activé au démarrage pour éviter les interruptions.

Cette procédure couvre tous les aspects critiques pour tester et valider une configuration système Linux en vue d’une installation MongoDB sur Ubuntu.

[1] https://go.lightnode.com/tech/install-mongodb-on-ubuntu
[2] https://www.scaleway.com/en/docs/tutorials/setup-mongodb-on-ubuntu/
[3] https://www.cherryservers.com/blog/install-mongodb-ubuntu-2404
[4] https://accuweb.cloud/resource/articles/mongodb-setup-on-ubuntu-22-04
[5] https://hostman.com/tutorials/install-mongodb-on-ubuntu-22-04/
[6] https://docs.vultr.com/install-and-configure-mongodb-database-server-on-ubuntu-20-04
[7] https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-20-04
[8] https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/
[9] https://www.ionos.fr/digitalguide/sites-internet/developpement-web/installer-mongodb-sur-ubuntu/
[10] https://stackoverflow.com/questions/51417708/unable-to-install-mongodb-properly-on-ubuntu-18-04-lts