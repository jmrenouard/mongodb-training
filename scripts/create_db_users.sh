#!/bin/bash

# Nom du script : generate_mongodb_users.sh
# Description : Installe pwgen, génère un mot de passe unique pour chaque utilisateur,
#               et écrit les commandes mongosh pour créer des utilisateurs
#               (ReadOnly, ReadWrite, Owner) pour une DB dans un fichier.
# Utilisation : bash ./generate_mongodb_users.sh <NOM_DE_LA_BASE_DE_DONNEES> [<FICHIER_SORTIE_COMMANDES>]
# Exemple : bash ./generate_mongodb_users.sh myappdb /tmp/create_users_myappdb.js
#           Si le fichier de sortie n'est pas spécifié, les commandes seront affichées sur la sortie standard.

DB_NAME="$1"
# Le port MongoDB est maintenant fixé à 27017 par défaut, non configurable via les arguments du script.
MONGO_PORT="27017" 

# Détermine le fichier de sortie. Si le deuxième argument est vide, affiche sur stdout.
if [ -z "$2" ]; then
    COMMANDS_OUTPUT_FILE="/dev/stdout" # Redirige vers la sortie standard
    # Les messages de préparation iront à stderr pour ne pas interférer avec le pipe
    echo "--- Les commandes mongosh seront affichées sur la sortie standard ---" >&2
else
    COMMANDS_OUTPUT_FILE="$2"
    echo "--- Les commandes mongosh seront écrites dans : ${COMMANDS_OUTPUT_FILE} ---" >&2
fi

# --- Vérification de l'argument de la base de données ---
if [ -z "$DB_NAME" ]; then
  echo "Usage: bash $0 <NOM_DE_LA_BASE_DE_DONNEES> [<FICHIER_SORTIE_COMMANDES>]" >&2
  echo "Exemple : bash $0 myappdb /tmp/create_users_myappdb.js" >&2
  exit 1
fi

echo "// --- Préparation pour la création d'utilisateurs MongoDB pour la DB : ${DB_NAME} ---" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Port MongoDB ciblé : ${MONGO_PORT}" >> "${COMMANDS_OUTPUT_FILE}"


# --- 1. Installation de pwgen si nécessaire ---
if ! command -v pwgen &> /dev/null; then
    echo "pwgen n'est pas installé. Installation..." >&2
    sudo apt-get update && sudo apt-get install -y pwgen
    if [ $? -ne 0 ]; then
        echo "Erreur: Impossible d'installer pwgen. Veuillez l'installer manuellement ou vérifier votre connexion internet." >&2
        exit 1
    fi
    echo "pwgen installé avec succès." >&2
else
    echo "pwgen est déjà installé." >&2
fi

# --- 2. Génération de mots de passe uniques pour chaque utilisateur ---
echo "" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Génération de mots de passe uniques de 12 caractères pour chaque utilisateur..." >> "${COMMANDS_OUTPUT_FILE}"

PASSWORD_READONLY=$(pwgen -s 12 1)
if [ -z "$PASSWORD_READONLY" ]; then echo "Erreur: Impossible de générer le mot de passe ReadOnly." >&2; exit 1; fi
echo "//   - ${DB_NAME}ReadOnly : ${PASSWORD_READONLY}" >> "${COMMANDS_OUTPUT_FILE}"

PASSWORD_READWRITE=$(pwgen -s 12 1)
if [ -z "$PASSWORD_READWRITE" ]; then echo "Erreur: Impossible de générer le mot de passe ReadWrite." >&2; exit 1; fi
echo "//   - ${DB_NAME}ReadWrite : ${PASSWORD_READWRITE}" >> "${COMMANDS_OUTPUT_FILE}"

PASSWORD_OWNER=$(pwgen -s 12 1)
if [ -z "$PASSWORD_OWNER" ]; then echo "Erreur: Impossible de générer le mot de passe Owner." >&2; exit 1; fi
echo "//   - ${DB_NAME}Owner    : ${PASSWORD_OWNER}" >> "${COMMANDS_OUTPUT_FILE}"

echo "" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Veuillez noter ces mots de passe de manière sécurisée. Ils ne seront pas affichés à nouveau." >> "${COMMANDS_OUTPUT_FILE}"
echo "" >> "${COMMANDS_OUTPUT_FILE}"

# --- 3. Définition des noms d'utilisateurs ---
USER_READONLY="${DB_NAME}ReadOnly"
USER_READWRITE="${DB_NAME}ReadWrite"
USER_OWNER="${DB_NAME}Owner"

echo "// --- Commandes mongosh pour créer les utilisateurs ---" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Ces commandes doivent être exécutées dans un shell mongosh connecté à l'instance MongoDB" >> "${COMMANDS_OUTPUT_FILE}"
echo "// avec un utilisateur ayant les privilèges suffisants (ex: root ou userAdminAnyDatabase)." >> "${COMMANDS_OUTPUT_FILE}"
echo "" >> "${COMMANDS_OUTPUT_FILE}"
echo "// Pour vous connecter au shell mongosh (si l'authentification est activée, utilisez un admin) :" >> "${COMMANDS_OUTPUT_FILE}"
echo "// mongosh --port ${MONGO_PORT} -u <admin_user> -p <admin_password> --authenticationDatabase admin" >> "${COMMANDS_OUTPUT_FILE}"
echo "// ou si l'authentification n'est pas encore activée (pour le premier admin) :" >> "${COMMANDS_OUTPUT_FILE}"
echo "// mongosh --port ${MONGO_PORT}" >> "${COMMANDS_OUTPUT_FILE}"
echo "" >> "${COMMANDS_OUTPUT_FILE}"
echo "// --- Copiez et collez les commandes suivantes dans votre shell mongosh ---" >> "${COMMANDS_OUTPUT_FILE}"
echo "" >> "${COMMANDS_OUTPUT_FILE}"

# Commande pour l'utilisateur ReadOnly
cat <<EOF >> "${COMMANDS_OUTPUT_FILE}"
use ${DB_NAME}
db.createUser(
  {
    "user": "${USER_READONLY}",
    "pwd": "${PASSWORD_READONLY}",
    "roles": [ { "role": "read", "db": "${DB_NAME}" } ]
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
    "user": "${USER_READWRITE}",
    "pwd": "${PASSWORD_READWRITE}",
    "roles": [ { "role": "readWrite", "db": "${DB_NAME}" } ]
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
    "user": "${USER_OWNER}",
    "pwd": "${PASSWORD_OWNER}",
    "roles": [ { "role": "dbOwner", "db": "${DB_NAME}" } ]
  }
)
EOF

echo "" >> "${COMMANDS_OUTPUT_FILE}"
if [ "$COMMANDS_OUTPUT_FILE" != "/dev/stdout" ]; then
    echo "Fichier de commandes mongosh créé avec succès : ${COMMANDS_OUTPUT_FILE}" >&2
    echo "" >&2
fi

# --- 4. Synthèse des utilisateurs créés (toujours sur stderr/stdout du terminal) ---
echo "--- Synthèse des utilisateurs créés pour la base de données '${DB_NAME}' ---" >&2
echo "" >&2
printf "%-25s | %-15s | %s\n" "Nom d'utilisateur" "Rôle" "Mot de passe" >&2
printf "%-25s | %-15s | %s\n" "-------------------------" "---------------" "----------------" >&2
printf "%-25s | %-15s | %s\n" "${USER_READONLY}" "read" "${PASSWORD_READONLY}" >&2
printf "%-25s | %-15s | %s\n" "${USER_READWRITE}" "readWrite" "${PASSWORD_READWRITE}" >&2
printf "%-25s | %-15s | %s\n" "${USER_OWNER}" "dbOwner" "${PASSWORD_OWNER}" >&2
echo "" >&2
echo "Pour exécuter ces commandes, connectez-vous à votre instance MongoDB avec un utilisateur administrateur, puis chargez le fichier :" >&2
echo "  mongosh --port ${MONGO_PORT} -u <admin_user> -p <admin_password> --authenticationDatabase admin --file ${COMMANDS_OUTPUT_FILE}" >&2
echo "" >&2
echo "N'oubliez pas d'activer l'authentification dans votre configuration MongoDB" >&2
echo "(security.authorization: enabled) et de redémarrer l'instance après avoir créé les utilisateurs." >&2
