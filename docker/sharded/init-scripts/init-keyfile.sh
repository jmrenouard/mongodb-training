#!/bin/bash

# Création du répertoire keyfile
mkdir -p ./data/keyfile

# Génération de la clé de réplication MongoDB
echo "$MONGO_REPLICA_SET_KEY" > ./data/keyfile/mongodb-keyfile

# Configuration des permissions (crucial pour la sécurité)
chmod 600 ./data/keyfile/mongodb-keyfile
chown 999:999 ./data/keyfile/mongodb-keyfile

echo "Keyfile généré avec succès dans ./data/keyfile/"
