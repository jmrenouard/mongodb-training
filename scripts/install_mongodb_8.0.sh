#!/bin/bash

# --- Configuration (Hypothétique pour MongoDB 8.0) ---
# NOTE: MongoDB 8.0 n'est pas encore officiellement sorti.
# Cette version est utilisée ici à titre d'exemple et pourrait changer.
MONGO_VERSION="8.0"
UBUNTU_RELEASE="noble" # Nom de la version d'Ubuntu 24.04

echo "Début de l'installation (hypothétique) de MongoDB ${MONGO_VERSION} sur Ubuntu ${UBUNTU_RELEASE}..."
echo "Veuillez noter que MongoDB 8.0 n'est pas encore une version stable et publique."
echo "Ce script est basé sur les procédures d'installation de MongoDB 7.0."

# --- 1. Importation de la clé GPG publique de MongoDB ---
echo "Importation de la clé GPG publique de MongoDB..."
# Installe les paquets nécessaires si ce n'est pas déjà fait
sudo apt-get update
sudo apt-get install -y gnupg curl

# Télécharge et importe la clé GPG.
# Pour une future version 8.0, l'URL de la clé pourrait être 'server-8.0.asc'
curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc | \
   sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGO_VERSION}.gpg

if [ $? -ne 0 ]; then
    echo "Erreur lors de l'importation de la clé GPG. Abandon."
    exit 1
fi
echo "Clé GPG importée avec succès."

# --- 2. Création du fichier de liste pour le dépôt MongoDB ---
echo "Création du fichier de liste pour le dépôt MongoDB..."
# Ajoute le dépôt MongoDB à la liste des sources d'APT.
# L'URL du dépôt et le nom de la version d'Ubuntu doivent correspondre.
echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-${MONGO_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_RELEASE}/mongodb-org/${MONGO_VERSION} multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list

if [ $? -ne 0 ]; then
    echo "Erreur lors de la création du fichier de dépôt. Abandon."
    exit 1
fi
echo "Fichier de dépôt créé avec succès."

# --- 3. Rechargement de la base de données des paquets locaux ---
echo "Rechargement de la base de données des paquets locaux..."
sudo apt-get update

if [ $? -ne 0 ]; then
    echo "Erreur lors de la mise à jour des paquets. Abandon."
    exit 1
fi
echo "Base de données des paquets rechargée."

# --- 4. Installation des paquets MongoDB ---
echo "Installation des paquets MongoDB (mongod, mongos, mongosh, mongodb-database-tools)..."
sudo apt-get install -y mongodb-org

if [ $? -ne 0 ]; then
    echo "Erreur lors de l'installation des paquets MongoDB. Abandon."
    exit 1
fi
echo "Paquets MongoDB installés avec succès."

# --- 5. Démarrage de MongoDB ---
echo "Démarrage du service mongod..."
sudo systemctl start mongod

if [ $? -ne 0 ]; then
    echo "Erreur lors du démarrage du service mongod. Vérifiez les journaux avec 'sudo journalctl -xeu mongod'."
    exit 1
fi
echo "Service mongod démarré."

# --- 6. Activation de MongoDB au démarrage du système ---
echo "Activation du service mongod au démarrage du système..."
sudo systemctl enable mongod

if [ $? -ne 0 ]; then
    echo "Erreur lors de l'activation du service mongod. Abandon."
    exit 1
fi
echo "Service mongod activé au démarrage."

# --- 7. Vérification du statut de MongoDB ---
echo "Vérification du statut du service mongod..."
sudo systemctl status mongod --no-pager

# --- 8. Test de connexion avec mongosh ---
echo "Test de connexion avec mongosh..."
echo "Pour vous connecter, tapez 'mongosh' dans votre terminal."
# mongosh --eval "db.adminCommand({ ping: 1 })"

echo ""
echo "Installation (hypothétique) de MongoDB ${MONGO_VERSION} terminée !"
echo "Vous pouvez vérifier le statut du service avec : sudo systemctl status mongod"
echo "Pour vous connecter au shell MongoDB : mongosh"
echo "Pour plus d'informations sur les outils, consultez la documentation MongoDB."
