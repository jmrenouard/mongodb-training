#!/bin/bash

# Nom du script : generate_mongodb_users.sh
# Description : Installe pwgen, génère un mot de passe unique pour chaque utilisateur,
#               et écrit les commandes mongosh pour créer des utilisateurs
#               (ReadOnly, ReadWrite, Owner) pour une DB dans un fichier.
# Utilisation : bash ./generate_mongodb_users.sh <NOM_DE_LA_BASE_DE_DONNEES> [<PORT_MONGODB>] <FICHIER_SORTIE_COMMANDES>
# Exemple : bash ./generate_mongodb_users.sh myappdb 27017 /tmp/create_users_myappdb.js
#           Si le port n'est pas spécifié, 27017 sera utilisé par défaut.

DB_NAME="$1"
MONGO_PORT="${2:-27017}" # Utilise 27017 par défaut si non spécifié
COMMANDS_OUTPUT_FILE="$3" # Fichier de sortie des commandes mongosh

# --- Vérification des arguments ---
if [ -z "$DB_NAME" ] || [ -z "$COMMANDS_OUTPUT_FILE" ]; then
  echo "Usage: bash $0 <NOM_DE_LA_BASE_DE_DONNEES> [<PORT_MONGODB>] <FICHIER_SORTIE_COMMANDES>"
  echo "Exemple : bash $0 myappdb 27017 /tmp/create_users_myappdb.js"
  exit 1
fi

echo "--- Préparation pour la création d'utilisateurs MongoDB pour la DB : ${DB_NAME} ---"
echo "Port MongoDB ciblé : ${MONGO_PORT}"
echo "Les commandes mongosh seront écrites dans : ${COMMANDS_OUTPUT_FILE}"

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

echo "--- Écriture des commandes mongosh dans le fichier ${COMMANDS_OUTPUT_FILE} ---"

# Initialiser le fichier de commandes
echo "// Commandes mongosh pour créer les utilisateurs de la base de données '${DB_NAME}'" > "${COMMANDS_OUTPUT_FILE}"
echo "// Généré par generate_mongodb_users.sh le $(date)" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Mot de passe ReadOnly: ${PASSWORD_READONLY}" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Mot de passe ReadWrite: ${PASSWORD_READWRITE}" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Mot de passe Owner: ${PASSWORD_OWNER}" >> "${COMMANDS_OUTPUT_FILE}"
echo "" >> "${COMMANDS_OUTPUT_FILE}"

# Commande pour l'utilisateur ReadOnly
cat <<EOF >> "${COMMANDS_OUTPUT_FILE}"
use ${DB_NAME}
db.createUser(
  {
    user: "${USER_READONLY}",
    pwd: "${PASSWORD_READONLY}",
    roles: [ { role: "read", db: "${DB_NAME}" } ]
  }
)
EOF

# Ajouter une ligne vide pour la lisibilité
echo "" >> "${COMMANDS_OUTPUT_FILE}"

# Commande pour l'utilisateur ReadWrite
cat <<EOF >> "${COMMANDS_OUTPUT_FILE}"
use ${DB_NAME}
db.createUser(
  {
    user: "${USER_READWRITE}",
    pwd: "${PASSWORD_READWRITE}",
    roles: [ { role: "readWrite", db: "${DB_NAME}" } ]
  }
)
EOF

# Ajouter une ligne vide pour la lisibilité
echo "" >> "${COMMANDS_OUTPUT_FILE}"

# Commande pour l'utilisateur Owner
cat <<EOF >> "${COMMANDS_OUTPUT_FILE}"
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
echo "Fichier de commandes mongosh créé avec succès : ${COMMANDS_OUTPUT_FILE}"
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
echo "Pour exécuter ces commandes, connectez-vous à votre instance MongoDB avec un utilisateur administrateur, puis chargez le fichier :"
echo "  mongosh --port ${MONGO_PORT} -u <admin_user> -p <admin_password> --authenticationDatabase admin --file ${COMMANDS_OUTPUT_FILE}"
echo ""
echo "N'oubliez pas d'activer l'authentification dans votre configuration MongoDB"
echo "(security.authorization: enabled) et de redémarrer l'instance après avoir créé les utilisateurs."
