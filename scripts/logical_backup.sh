#!/bin/bash

# Nom du script : mongodb_backup.sh
# Description : Effectue une sauvegarde logique (mongodump) de MongoDB pour différentes topologies.
#               Inclut la vérification du répertoire, la somme de contrôle SHA256 et l'encryption optionnelle.
# Utilisation :
#   Pour Standalone :
#     bash ./mongodb_backup.sh standalone <HOST> <PORT> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD]
#     Ex: bash ./mongodb_backup.sh standalone localhost 27017 admin mysecret admin myEncryptionKey
#
#   Pour Replica Set :
#     bash ./mongodb_backup.sh replicaset <HOST> <PORT> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD]
#     (HOST et PORT peuvent être n'importe quel membre du replica set, le script trouvera le primaire)
#     Ex: bash ./mongodb_backup.sh replicaset rs0member1.example.com 27017 admin mysecret admin myEncryptionKey
#
#   Pour Sharded Cluster :
#     bash ./mongodb_backup.sh sharded <MONGOS_HOST> <MONGOS_PORT> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD]
#     Ex: bash ./mongodb_backup.sh sharded mongos1.example.com 27020 admin mysecret admin myEncryptionKey

# --- Configuration Globale ---
BACKUP_BASE_DIR="/var/backups/mongodb" # Répertoire de base pour toutes les sauvegardes
LOG_FILE="${BACKUP_BASE_DIR}/mongodb_backup.log" # Fichier de log pour le script
TIMESTAMP=$(date +"%Y%m%d_%H%M%S") # Horodatage pour les répertoires de sauvegarde

# Rediriger stdout et stderr vers le fichier de log et la console dès le début
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "--- Démarrage de la sauvegarde MongoDB ---"
echo "Date et heure : ${TIMESTAMP}"
echo "Fichier de log : ${LOG_FILE}"
echo ""

# --- Vérification et création du répertoire de base des sauvegardes ---
echo "Vérification et création du répertoire de sauvegarde : ${BACKUP_BASE_DIR}..."
mkdir -p "${BACKUP_BASE_DIR}"
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de créer le répertoire de sauvegarde ${BACKUP_BASE_DIR}. Vérifiez les permissions."
    exit 1
fi
echo "Répertoire de sauvegarde vérifié/créé."
echo ""

# --- Fonctions Utilitaires ---

# Fonction pour ajouter des identifiants à la commande mongodump
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

# Fonction pour trouver le primaire d'un replica set
find_primary() {
    local host="$1"
    local port="$2"
    local auth_str="$3"
    local primary_info

    echo "Tentative de trouver le primaire du replica set via ${host}:${port}..."
    # Utilise mongosh pour obtenir le nom d'hôte et le port du primaire
    primary_info=$(mongosh --host "${host}" --port "${port}" ${auth_str} --eval "JSON.stringify(rs.isMaster().primary)" --quiet)
    
    if [ $? -ne 0 ] || [ -z "$primary_info" ] || [ "$primary_info" == "null" ]; then
        echo "Erreur: Impossible de trouver le primaire du replica set via ${host}:${port}. Vérifiez la connectivité, les identifiants et le statut du replica set."
        return 1
    fi

    # Supprime les guillemets du résultat JSON.stringify
    primary_info=$(echo "$primary_info" | tr -d '"')
    echo "Primaire trouvé : ${primary_info}"
    echo "$primary_info" # Retourne le host:port du primaire
    return 0
}

# --- Logique de Sauvegarde ---

BACKUP_TYPE="$1"
HOST="$2"
PORT="$3"
USERNAME="$4"
PASSWORD="$5"
AUTH_DB="${6:-admin}" # Base d'authentification par défaut à 'admin'
ENCRYPTION_PASSWORD="$7" # Nouveau paramètre pour le mot de passe d'encryption

AUTH_COMMAND_STRING=$(build_auth_string "$USERNAME" "$PASSWORD" "$AUTH_DB")
OPLOG_OPTION="" # Initialiser à vide

case "$BACKUP_TYPE" in
    standalone)
        echo "Type de sauvegarde : Standalone"
        TARGET_HOST="${HOST}"
        TARGET_PORT="${PORT}"
        ;;
    replicaset)
        echo "Type de sauvegarde : Replica Set"
        PRIMARY_ADDRESS=$(find_primary "$HOST" "$PORT" "$AUTH_COMMAND_STRING")
        if [ $? -ne 0 ]; then
            echo "Échec de la sauvegarde du replica set : Impossible de déterminer le primaire."
            exit 1
        fi
        TARGET_HOST=$(echo "$PRIMARY_ADDRESS" | cut -d':' -f1)
        TARGET_PORT=$(echo "$PRIMARY_ADDRESS" | cut -d':' -f2)
        # Pour les replica sets, --oplog est crucial pour la cohérence et la restauration point-in-time
        OPLOG_OPTION="--oplog"
        ;;
    sharded)
        echo "Type de sauvegarde : Sharded Cluster (via mongos)"
        TARGET_HOST="${HOST}" # C'est l'hôte du mongos
        TARGET_PORT="${PORT}" # C'est le port du mongos
        # Pour les clusters shardés, --oplog est également crucial
        OPLOG_OPTION="--oplog"
        ;;
    *)
        echo "Usage: $0 {standalone|replicaset|sharded} <HOST> <PORT> [USERNAME] [PASSWORD] [AUTH_DB] [ENCRYPTION_PASSWORD]"
        echo "Erreur: Type de sauvegarde non valide. Utilisez 'standalone', 'replicaset' ou 'sharded'."
        exit 1
        ;;
esac

# Répertoire de sortie pour cette sauvegarde spécifique
BACKUP_DIR_RAW="${BACKUP_BASE_DIR}/${BACKUP_TYPE}_${HOST}_${PORT}_${TIMESTAMP}"
mkdir -p "${BACKUP_DIR_RAW}"
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de créer le répertoire de sauvegarde ${BACKUP_DIR_RAW}. Vérifiez les permissions."
    exit 1
fi

echo "Démarrage de mongodump pour ${TARGET_HOST}:${TARGET_PORT}..."
echo "Répertoire de sauvegarde temporaire : ${BACKUP_DIR_RAW}"

# Exécution de mongodump
mongodump --host "${TARGET_HOST}" --port "${TARGET_PORT}" ${AUTH_COMMAND_STRING} ${OPLOG_OPTION} --out "${BACKUP_DIR_RAW}"
MONGODUMP_EXIT_CODE=$?

if [ ${MONGODUMP_EXIT_CODE} -eq 0 ]; then
    echo "Sauvegarde mongodump terminée avec succès."

    # --- Compression de la sauvegarde ---
    echo "Compression de la sauvegarde..."
    TAR_FILE="${BACKUP_BASE_DIR}/${BACKUP_TYPE}_${HOST}_${PORT}_${TIMESTAMP}.tar.gz"
    tar -czf "${TAR_FILE}" -C "${BACKUP_BASE_DIR}" "$(basename "${BACKUP_DIR_RAW}")"
    TAR_EXIT_CODE=$?

    if [ ${TAR_EXIT_CODE} -eq 0 ]; then
        echo "Sauvegarde compressée avec succès : ${TAR_FILE}"

        # --- Somme de contrôle SHA256 ---
        echo "Calcul de la somme de contrôle SHA256..."
        sha256sum "${TAR_FILE}" > "${TAR_FILE}.sha256"
        SHA256_EXIT_CODE=$?
        if [ ${SHA256_EXIT_CODE} -eq 0 ]; then
            echo "Somme de contrôle SHA256 générée : ${TAR_FILE}.sha256"
        else
            echo "Avertissement: Échec du calcul de la somme de contrôle SHA256."
        fi

        # --- Encryption optionnelle ---
        if [ -n "$ENCRYPTION_PASSWORD" ]; then
            echo "Encryption de la sauvegarde..."
            ENCRYPTED_FILE="${TAR_FILE}.enc"
            openssl enc -aes-256-cbc -salt -in "${TAR_FILE}" -out "${ENCRYPTED_FILE}" -k "${ENCRYPTION_PASSWORD}"
            ENCRYPTION_EXIT_CODE=$?

            if [ ${ENCRYPTION_EXIT_CODE} -eq 0 ]; then
                echo "Sauvegarde encryptée avec succès : ${ENCRYPTED_FILE}"
                echo "Suppression du fichier non encrypté : ${TAR_FILE}"
                rm -f "${TAR_FILE}"
                if [ $? -eq 0 ]; then
                    echo "Fichier non encrypté supprimé."
                else
                    echo "Avertissement: Impossible de supprimer le fichier non encrypté. Nettoyage manuel requis."
                fi
            else
                echo "Erreur: Échec de l'encryption de la sauvegarde."
                echo "Le fichier compressé non encrypté est toujours disponible à : ${TAR_FILE}"
            fi
        fi

        # --- Nettoyage (suppression du répertoire non compressé) ---
        echo "Nettoyage du répertoire de sauvegarde temporaire : ${BACKUP_DIR_RAW}"
        rm -rf "${BACKUP_DIR_RAW}"
        if [ $? -eq 0 ]; then
            echo "Nettoyage terminé."
        else
            echo "Avertissement: Impossible de supprimer le répertoire temporaire. Nettoyage manuel requis."
        fi
    else
        echo "Erreur: Échec de la compression de la sauvegarde."
        echo "Le répertoire non compressé est toujours disponible à : ${BACKUP_DIR_RAW}"
        exit 1 # Sortir si la compression échoue
    fi
else
    echo "Erreur: Échec de la sauvegarde mongodump (code de sortie: ${MONGODUMP_EXIT_CODE})."
    echo "Vérifiez les logs de MongoDB, la connectivité et les identifiants."
    echo "Le répertoire de sauvegarde incomplet est à : ${BACKUP_DIR_RAW}"
    exit 1 # Sortir si mongodump échoue
fi

echo ""
echo "--- Sauvegarde MongoDB terminée ---"
if [ -n "$ENCRYPTION_PASSWORD" ]; then
    echo "Pour déchiffrer le fichier de sauvegarde (par exemple, ${ENCRYPTED_FILE}) :"
    echo "  openssl enc -aes-256-cbc -d -in \"${ENCRYPTED_FILE}\" -out \"${TAR_FILE}\" -k \"${ENCRYPTION_PASSWORD}\""
    echo "Puis pour décompresser :"
    echo "  tar -xzf \"${TAR_FILE}\" -C \"/votre/repertoire/de/restauration\""
else
    echo "Pour décompresser le fichier de sauvegarde (par exemple, ${TAR_FILE}) :"
    echo "  tar -xzf \"${TAR_FILE}\" -C \"/votre/repertoire/de/restauration\""
fi
