#!/bin/bash

# Nom du script : generate_mongodb_users.sh
# Description : Installe pwgen, génère un mot de passe, et affiche les commandes mongosh
#               pour créer des utilisateurs (ReadOnly, ReadWrite, Owner) pour une DB.
# Utilisation : bash ./generate_mongodb_users.sh <NOM_DE_LA_BASE_DE_DONNEES> [<PORT_MONGODB>]
# Exemple : bash ./generate_mongodb_users.sh myappdb 27017
#           Si le port n'est pas spécifié, 27017 sera utilisé par défaut.

DB_NAME="$1"
MONGO_PORT="${2:-27017}" # Utilise 27017 par défaut si non spécifié

# --- Vérification de l'argument de la base de données ---
if [ -z "$DB_NAME" ]; then
  echo "Usage: bash $0 <NOM_DE_LA_BASE_DE_DONNEES> [<PORT_MONGODB>]"
  echo "Exemple: bash $0 myappdb 27017"
  exit 1
fi

echo "--- Préparation pour la création d'utilisateurs MongoDB pour la DB : ${DB_NAME} ---"
echo "Port MongoDB ciblé : ${MONGO_PORT}"

# --- 1. Installation de pwgen si nécessaire ---
if ! command -v pwgen &> /dev/null; then
    echo "pwgen n'est pas installé. Installation..."
    sudo apt-get update && sudo apt-get install -y pwgen
    if [ $? -ne 0 ]; then
        echo "Erreur: Impossible d'installer pwgen. Veuillez l'installer manuellement ou vérifier votre connexion internet."
        exit 1
    fi
    echo "pwgen installé avec succès."
else
    echo "pwgen est déjà installé."
fi

# --- 2. Génération d'un mot de passe de 12 caractères ---
GENERATED_PASSWORD=$(pwgen -s 12 1)
if [ -z "$GENERATED_PASSWORD" ]; then
    echo "Erreur: Impossible de générer le mot de passe. pwgen a échoué."
    exit 1
fi

echo ""
echo "Mot de passe généré (à utiliser pour tous les utilisateurs de cette DB) : ${GENERATED_PASSWORD}"
echo "Veuillez noter ce mot de passe de manière sécurisée. Il ne sera pas affiché à nouveau."
echo ""

# --- 3. Définition des noms d'utilisateurs ---
USER_READONLY="${DB_NAME}ReadOnly"
USER_READWRITE="${DB_NAME}ReadWrite"
USER_OWNER="${DB_NAME}Owner"

echo "--- Commandes mongosh pour créer les utilisateurs ---"
echo "Ces commandes doivent être exécutées dans un shell mongosh connecté à l'instance MongoDB"
echo "avec un utilisateur ayant les privilèges suffisants (ex: root ou userAdminAnyDatabase)."
echo ""
echo "Pour vous connecter au shell mongosh (si l'authentification est activée, utilisez un admin) :"
echo "mongosh --port ${MONGO_PORT} -u <admin_user> -p <admin_password> --authenticationDatabase admin"
echo "ou si l'authentification n'est pas encore activée (pour le premier admin) :"
echo "mongosh --port ${MONGO_PORT}"
echo ""
echo "--- Copiez et collez les commandes suivantes dans votre shell mongosh ---"
echo ""

# Commande pour l'utilisateur ReadOnly
cat <<EOF
use ${DB_NAME}
db.createUser(
  {
    user: "${USER_READONLY}",
    pwd: "${GENERATED_PASSWORD}",
    roles: [ { role: "read", db: "${DB_NAME}" } ]
  }
)
EOF

echo ""

# Commande pour l'utilisateur ReadWrite
cat <<EOF
use ${DB_NAME}
db.createUser(
  {
    user: "${USER_READWRITE}",
    pwd: "${GENERATED_PASSWORD}",
    roles: [ { role: "readWrite", db: "${DB_NAME}" } ]
  }
)
EOF

echo ""

# Commande pour l'utilisateur Owner
cat <<EOF
use ${DB_NAME}
db.createUser(
  {
    user: "${USER_OWNER}",
    pwd: "${GENERATED_PASSWORD}",
    roles: [ { role: "dbOwner", db: "${DB_NAME}" } ]
  }
)
EOF

echo ""
echo "--- Fin des commandes de création d'utilisateurs ---"
echo "N'oubliez pas d'activer l'authentification dans votre configuration MongoDB"
echo "(security.authorization: enabled) et de redémarrer l'instance après avoir créé les utilisateurs."
