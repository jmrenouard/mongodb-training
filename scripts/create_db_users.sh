#!/bin/bash

# Nom du script : generate_mongodb_users.sh
# Description : Installe pwgen, génère un mot de passe unique pour chaque utilisateur,
#               et affiche les commandes mongosh pour créer des utilisateurs
#               (ReadOnly, ReadWrite, Owner) pour une DB, puis une synthèse finale.
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

# --- 2. Génération de mots de passe uniques pour chaque utilisateur ---
echo ""
echo "Génération de mots de passe uniques de 12 caractères pour chaque utilisateur..."

PASSWORD_READONLY=$(pwgen -s 12 1)
if [ -z "$PASSWORD_READONLY" ]; then echo "Erreur: Impossible de générer le mot de passe ReadOnly."; exit 1; fi
echo "  - ${DB_NAME}ReadOnly : ${PASSWORD_READONLY}"

PASSWORD_READWRITE=$(pwgen -s 12 1)
if [ -z "$PASSWORD_READWRITE" ]; then echo "Erreur: Impossible de générer le mot de passe ReadWrite."; exit 1; fi
echo "  - ${DB_NAME}ReadWrite : ${PASSWORD_READWRITE}"

PASSWORD_OWNER=$(pwgen -s 12 1)
if [ -z "$PASSWORD_OWNER" ]; then echo "Erreur: Impossible de générer le mot de passe Owner."; exit 1; fi
echo "  - ${DB_NAME}Owner    : ${PASSWORD_OWNER}"

echo ""
echo "Veuillez noter ces mots de passe de manière sécurisée. Ils ne seront pas affichés à nouveau."
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
    pwd: "${PASSWORD_READONLY}",
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
    pwd: "${PASSWORD_READWRITE}",
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
    pwd: "${PASSWORD_OWNER}",
    roles: [ { role: "dbOwner", db: "${DB_NAME}" } ]
  }
)
EOF

echo ""
echo "--- Fin des commandes de création d'utilisateurs ---"
echo ""

# --- 4. Synthèse des utilisateurs créés ---
echo "--- Synthèse des utilisateurs créés pour la base de données '${DB_NAME}' ---"
echo ""
printf "%-25s | %-15s | %s\n" "Nom d'utilisateur" "Rôle" "Mot de passe"
printf "%-25s | %-15s | %s\n" "-------------------------" "---------------" "----------------"
printf "%-25s | %-15s | %s\n" "${USER_READONLY}" "read" "${PASSWORD_READONLY}"
printf "%-25s | %-15s | %s\n" "${USER_READWRITE}" "readWrite" "${PASSWORD_READWRITE}"
printf "%-25s | %-15s | %s\n" "${USER_OWNER}" "dbOwner" "${PASSWORD_OWNER}"
echo ""
echo "N'oubliez pas d'activer l'authentification dans votre configuration MongoDB"
echo "(security.authorization: enabled) et de redémarrer l'instance après avoir créé les utilisateurs."
