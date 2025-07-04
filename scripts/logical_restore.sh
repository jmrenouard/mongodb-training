#!/bin/bash

# Nom du script : mongodb_restore.sh
# Description : Restaure une sauvegarde logique (mongodump) de MongoDB.
# Utilisation :
#   bash ./mongodb_restore.sh <FICHIER_DE_SAUVEGARDE> <HOST_CIBLE> <PORT_CIBLE> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD] [--drop]
#
# Arguments :
#   <FICHIER_DE_SAUVEGARDE> : Chemin complet vers le fichier .tar.gz ou .tar.gz.enc de la sauvegarde.
#   <HOST_CIBLE>            : Hôte de l'instance MongoDB où restaurer (primaire pour RS, mongos pour Sharded).
#   <PORT_CIBLE>            : Port de l'instance MongoDB cible.
#   [USERNAME]              : (Optionnel) Nom d'utilisateur MongoDB pour la restauration.
#   [PASSWORD]              : (Optionnel) Mot de passe de l'utilisateur MongoDB.
#   [AUTH_DB]               : (Optionnel, par défaut 'admin') Base d'authentification de l'utilisateur.
#   [ENCRYPTION_PASSWORD]   : (Optionnel) Mot de passe utilisé pour encrypter la sauvegarde.
#   [--drop]                : (Optionnel) Si présent, supprime les collections existantes avant la restauration.

# --- Configuration Globale ---
TEMP_RESTORE_DIR="/tmp/mongodb_restore_$(date +"%Y%m%d_%H%M%S")" # Répertoire temporaire pour la décompression
LOG_FILE="/var/log/mongodb/mongodb_restore.log" # Fichier de log pour le script
TIMESTAMP=$(date +"%Y%m%d_%H%M%S") # Horodatage pour les logs

# Rediriger stdout et stderr vers le fichier de log et la console
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "--- Démarrage de la restauration MongoDB ---"
echo "Date et heure : ${TIMESTAMP}"
echo "Fichier de log : ${LOG_FILE}"
echo ""

# --- Vérification des arguments ---
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <FICHIER_DE_SAUVEGARDE> <HOST_CIBLE> <PORT_CIBLE> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD] [--drop]"
    echo "Erreur: Arguments insuffisants."
    exit 1
fi

BACKUP_FILE="$1"
TARGET_HOST="$2"
TARGET_PORT="$3"

# Décalage des arguments pour récupérer les options optionnelles
shift 3
USERNAME="$1"
PASSWORD="$2"
AUTH_DB="${3:-admin}"
ENCRYPTION_PASSWORD="$4"
DROP_OPTION=""

# Vérifier si l'option --drop est présente
for arg in "$@"; do
    if [ "$arg" == "--drop" ]; then
        DROP_OPTION="--drop"
        echo "Option --drop activée : les collections existantes seront supprimées avant la restauration."
        break
    fi
done

# --- Vérification de l'existence du fichier de sauvegarde ---
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Erreur: Le fichier de sauvegarde '${BACKUP_FILE}' n'existe pas."
    exit 1
fi

echo "Fichier de sauvegarde : ${BACKUP_FILE}"
echo "Cible de restauration : ${TARGET_HOST}:${TARGET_PORT}"
echo ""

# --- Fonctions Utilitaires ---

# Fonction pour ajouter des identifiants à la commande mongorestore
build_auth_string() {
    local username="$1"
    local password="$2"
    local auth_db="$3"
    local auth_str=""
    if [ -n "$username" ] && [ -n "$password" ]; then
        auth_str="--username ${username} --password ${password} --authenticationDatabase ${auth_db}"
    fi
    echo "$auth_str"
}

AUTH_COMMAND_STRING=$(build_auth_string "$USERNAME" "$PASSWORD" "$AUTH_DB")

# --- Déchiffrement (si le fichier est encrypté) ---
DECRYPTED_TAR_FILE="${BACKUP_FILE}" # Par défaut, pas de déchiffrement
if [[ "${BACKUP_FILE}" == *.enc ]]; then
    echo "Le fichier de sauvegarde est encrypté. Tentative de déchiffrement..."
    if [ -z "$ENCRYPTION_PASSWORD" ]; then
        echo "Erreur: Le fichier est encrypté mais aucun mot de passe d'encryption n'a été fourni."
        exit 1
    fi
    DECRYPTED_TAR_FILE="${BACKUP_FILE%.enc}" # Nom du fichier après déchiffrement
    openssl enc -aes-256-cbc -d -in "${BACKUP_FILE}" -out "${DECRYPTED_TAR_FILE}" -k "${ENCRYPTION_PASSWORD}"
    if [ $? -ne 0 ]; then
        echo "Erreur: Échec du déchiffrement du fichier '${BACKUP_FILE}'. Vérifiez le mot de passe."
        exit 1
    fi
    echo "Fichier déchiffré avec succès vers '${DECRYPTED_TAR_FILE}'."
fi

# --- Décompression ---
echo "Création du répertoire temporaire pour la restauration : ${TEMP_RESTORE_DIR}"
mkdir -p "${TEMP_RESTORE_DIR}"
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de créer le répertoire temporaire ${TEMP_RESTORE_DIR}. Vérifiez les permissions."
    exit 1
fi

echo "Décompression de la sauvegarde..."
tar -xzf "${DECRYPTED_TAR_FILE}" -C "${TEMP_RESTORE_DIR}"
if [ $? -ne 0 ]; then
    echo "Erreur: Échec de la décompression du fichier '${DECRYPTED_TAR_FILE}'. Le fichier est peut-être corrompu ou le format est incorrect."
    # Nettoyage du fichier déchiffré si créé
    if [[ "${BACKUP_FILE}" == *.enc ]]; then
        echo "Suppression du fichier déchiffré temporaire : ${DECRYPTED_TAR_FILE}"
        rm -f "${DECRYPTED_TAR_FILE}"
    fi
    exit 1
fi
echo "Décompression terminée."

# Trouver le répertoire de données extrait (il y en a généralement un seul)
EXTRACTED_DATA_DIR=$(find "${TEMP_RESTORE_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)
if [ -z "$EXTRACTED_DATA_DIR" ]; then
    echo "Erreur: Aucun répertoire de données MongoDB trouvé après décompression dans ${TEMP_RESTORE_DIR}."
    exit 1
fi
echo "Répertoire de données extrait : ${EXTRACTED_DATA_DIR}"

# Déterminer si --oplogReplay est nécessaire
# Le type de backup est encodé dans le nom du fichier de sauvegarde
FILENAME_NO_EXT=$(basename "${DECRYPTED_TAR_FILE}" .tar.gz)
BACKUP_TYPE_FROM_FILENAME=$(echo "${FILENAME_NO_EXT}" | cut -d'_' -f1)

OPLOG_REPLAY_OPTION=""
if [[ "${BACKUP_TYPE_FROM_FILENAME}" == "replicaset" || "${BACKUP_TYPE_FROM_FILENAME}" == "sharded" ]]; then
    OPLOG_REPLAY_OPTION="--oplogReplay"
    echo "La sauvegarde provient d'un replica set ou d'un cluster shardé. L'option --oplogReplay sera utilisée."
fi

# --- Restauration avec mongorestore ---
echo "Démarrage de la restauration avec mongorestore..."
mongorestore --host "${TARGET_HOST}" --port "${TARGET_PORT}" ${AUTH_COMMAND_STRING} ${DROP_OPTION} ${OPLOG_REPLAY_OPTION} "${EXTRACTED_DATA_DIR}"
MONGORESTORE_EXIT_CODE=$?

if [ ${MONGORESTORE_EXIT_CODE} -eq 0 ]; then
    echo "Restauration mongorestore terminée avec succès."
else
    echo "Erreur: Échec de la restauration mongorestore (code de sortie: ${MONGORESTORE_EXIT_CODE})."
    echo "Vérifiez les logs de MongoDB, la connectivité, les identifiants et les permissions de l'utilisateur MongoDB."
    exit 1
fi

# --- Nettoyage ---
echo "Nettoyage des fichiers temporaires..."
# Supprimer le répertoire temporaire de décompression
rm -rf "${TEMP_RESTORE_DIR}"
if [ $? -eq 0 ]; then
    echo "Répertoire temporaire supprimé : ${TEMP_RESTORE_DIR}"
else
    echo "Avertissement: Impossible de supprimer le répertoire temporaire. Nettoyage manuel requis : ${TEMP_RESTORE_DIR}"
fi

# Supprimer le fichier déchiffré temporaire si créé
if [[ "${BACKUP_FILE}" == *.enc ]]; then
    echo "Suppression du fichier déchiffré temporaire : ${DECRYPTED_TAR_FILE}"
    rm -f "${DECRYPTED_TAR_FILE}"
    if [ $? -eq 0 ]; then
        echo "Fichier déchiffré temporaire supprimé."
    else
        echo "Avertissement: Impossible de supprimer le fichier déchiffré temporaire. Nettoyage manuel requis."
    fi
fi

echo ""
echo "--- Restauration MongoDB terminée ---"
echo "Vérifiez l'intégrité des données dans votre instance MongoDB."
