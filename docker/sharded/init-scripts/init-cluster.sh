#!/bin/bash
# Arrête le script si une commande échoue
set -e

echo "Attente du démarrage complet du cluster... (30s)"
sleep 30

echo "--- Initialisation des Replica Sets ---"
mongosh --host mongos-router-1:27017 -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin /scripts/init-replica-sets.js

echo "--- Création des utilisateurs ---"
mongosh --host mongos-router-1:27017 -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin /scripts/init-users.js

echo "--- Initialisation terminée avec succès ---"