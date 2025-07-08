#!/bin/bash

# ===============================================
# Configuration des Sauvegardes MongoDB
# ===============================================

# Répertoire de base des sauvegardes (à personnaliser)
BACKUP_DIR="/data/mongodb_backups"

# Hôte et Port MongoDB
MONGO_HOST="localhost"
MONGO_PORT="27017"

# Optionnel : Nom d'utilisateur et mot de passe si authentification activée
# MONGO_USER="your_mongo_user"
# MONGO_PASS="your_mongo_password"

# Base de données à sauvegarder (laissez vide pour toutes les bases, ex: "my_database")
DB_NAME=""

# Nombre de sauvegardes complètes à conserver
FULL_BACKUP_RETENTION=7 # Conserve 7 jours de sauvegardes complètes

# Nombre de sauvegardes incrémentielles à conserver par sauvegarde complète de référence
INCREMENTAL_BACKUP_RETENTION=30 # Conserve les incrémentielles des 30 derniers jours pour chaque full de référence

# Fichier de log
LOG_FILE="${BACKUP_DIR}/mongodb_backup.log"

# Fichier pour stocker le dernier timestamp de l'oplog pour les sauvegardes incrémentielles
OPLOG_TIMESTAMP_FILE="${BACKUP_DIR}/oplog_timestamp.txt"

# ===============================================
# Structure des Répertoires de Sauvegarde
# ===============================================
# Les sauvegardes seront organisées comme suit :
#
# <BACKUP_DIR>/
# ├── full/
# │   ├── <TIMESTAMP_FULL_1>/          # Ex: 20240707_103000/ (contient le dump complet et oplog_start_timestamp.txt)
# │   ├── <TIMESTAMP_FULL_2>/
# │   └── ...
# └── incremental/
#     ├── <TIMESTAMP_FULL_REF_1>/      # Référence à une sauvegarde complète (même nom que le répertoire full)
#     │   ├── inc_<TIMESTAMP_INC_1>/   # Ex: inc_20240707_110000/ (contient le dump d'oplog incrémentiel)
#     │   ├── inc_<TIMESTAMP_INC_2>/
#     │   └── ...
#     ├── <TIMESTAMP_FULL_REF_2>/
#     │   ├── inc_<TIMESTAMP_INC_1>/
#     └── ...
#
# Où <TIMESTAMP> est au format YYYYMMDD_HHmmss.
# Le fichier oplog_timestamp.txt stocke le dernier timestamp de l'oplog utilisé pour la prochaine
# sauvegarde incrémentielle.

# ===============================================
# Fonctions d'Utilitaires
# ===============================================

log_message() {
    local type="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$type] $message" | tee -a "$LOG_FILE"
}

error_exit() {
    log_message "ERROR" "$1"
    exit 1
}

# ===============================================
# Main Script Logic
# ===============================================

# Créer les répertoires nécessaires si ils n'existent pas
mkdir -p "${BACKUP_DIR}/full" || error_exit "Impossible de créer le répertoire de sauvegardes full."
mkdir -p "${BACKUP_DIR}/incremental" || error_exit "Impossible de créer le répertoire de sauvegardes incremental."
touch "$LOG_FILE" || error_exit "Impossible de créer le fichier de log."

# Vérifier si mongodump est installé
command -v mongodump >/dev/null 2>&1 || error_exit "mongodump n'est pas trouvé. Veuillez l'installer."

# Options d'authentification pour mongodump
AUTH_OPTIONS=""
# if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASS" ]; then
#     AUTH_OPTIONS="--username $MONGO_USER --password $MONGO_PASS"
# fi

# Fonction pour gérer la rotation des sauvegardes
rotate_backups() {
    local backup_type="$1" # 'full' or 'incremental'
    local retention="$2"
    local base_dir=""

    if [ "$backup_type" == "full" ]; then
        base_dir="${BACKUP_DIR}/full"
        log_message "INFO" "Rotation des sauvegardes complètes (rétention: ${retention} jours)."
        # Supprime les répertoires de sauvegarde full plus anciens que la rétention
        find "$base_dir" -maxdepth 1 -type d -name "????????_??????*" -mtime +$((retention-1)) -exec rm -rf {} \;
    elif [ "$backup_type" == "incremental" ]; then
        local full_ref_dir="$3" # Le répertoire de la sauvegarde complète de référence
        base_dir="${full_ref_dir}"
        log_message "INFO" "Rotation des sauvegardes incrémentielles pour ${full_ref_dir} (rétention: ${retention} jours)."
        # Supprime les répertoires de sauvegarde incrémentielle plus anciens que la rétention
        find "$base_dir" -maxdepth 1 -type d -name "inc_????????_??????*" -mtime +$((retention-1)) -exec rm -rf {} \;
    fi
}

# Fonction pour réaliser une sauvegarde complète
perform_full_backup() {
    log_message "INFO" "Démarrage de la sauvegarde complète..."
    CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
    FULL_BACKUP_PATH="${BACKUP_DIR}/full/${CURRENT_DATE}"
    OPLOG_START_TIMESTAMP_FILE="${FULL_BACKUP_PATH}/oplog_start_timestamp.txt"

    mkdir -p "$FULL_BACKUP_PATH" || error_exit "Impossible de créer le répertoire de sauvegarde complète: $FULL_BACKUP_PATH"

    local DUMP_COMMAND="mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} ${AUTH_OPTIONS}"

    if [ -n "$DB_NAME" ]; then
        DUMP_COMMAND="$DUMP_COMMAND --db $DB_NAME"
    fi

    # Capture du timestamp de l'oplog avant le dump
    # Ceci est crucial pour les sauvegardes incrémentielles.
    OPLOG_START=$(mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} ${AUTH_OPTIONS} --oplog --oplogArbiterOnly --out /dev/null 2>&1 | grep "oplog: { ts: Timestamp" | awk -F'Timestamp(' '{print $2}' | awk -F', ' '{print $1}')
    if [ -z "$OPLOG_START" ]; then
        log_message "WARNING" "Impossible de récupérer le timestamp initial de l'oplog. Les sauvegardes incrémentielles pourraient être affectées."
    else
        echo "$OPLOG_START" > "$OPLOG_START_TIMESTAMP_FILE"
        log_message "INFO" "Timestamp de l'oplog au début de la sauvegarde complète: $OPLOG_START"
    fi

    log_message "INFO" "Exécution de la commande: $DUMP_COMMAND --out $FULL_BACKUP_PATH"
    if ! eval "$DUMP_COMMAND --out $FULL_BACKUP_PATH"; then
        error_exit "La sauvegarde complète a échoué. Vérifiez les logs pour plus de détails."
    fi

    log_message "INFO" "Sauvegarde complète terminée avec succès dans $FULL_BACKUP_PATH."
    rotate_backups "full" "$FULL_BACKUP_RETENTION"
    # Mettre à jour le dernier timestamp de l'oplog après une sauvegarde full
    # Ce timestamp sera utilisé comme point de départ pour la prochaine sauvegarde incrémentielle
    if [ -f "$OPLOG_START_TIMESTAMP_FILE" ]; then
        cp "$OPLOG_START_TIMESTAMP_FILE" "$OPLOG_TIMESTAMP_FILE"
        log_message "INFO" "Mis à jour du fichier de timestamp de l'oplog: $(cat "$OPLOG_TIMESTAMP_FILE")"
    fi
}

# Fonction pour réaliser une sauvegarde incrémentielle
perform_incremental_backup() {
    log_message "INFO" "Démarrage de la sauvegarde incrémentielle..."

    # Vérifier si le fichier de timestamp de l'oplog existe
    if [ ! -f "$OPLOG_TIMESTAMP_FILE" ]; then
        error_exit "Le fichier de timestamp de l'oplog (${OPLOG_TIMESTAMP_FILE}) est introuvable. Exécutez une sauvegarde complète d'abord."
    fi

    LAST_OPLOG_TS=$(cat "$OPLOG_TIMESTAMP_FILE")
    if [ -z "$LAST_OPLOG_TS" ]; then
        error_exit "Le timestamp de l'oplog est vide. Exécutez une sauvegarde complète d'abord."
    fi

    # Trouver la dernière sauvegarde complète pour servir de référence
    # Les sauvegardes incrémentielles sont stockées sous le répertoire de leur sauvegarde complète de référence
    LATEST_FULL_BACKUP_DIR=$(find "${BACKUP_DIR}/full" -maxdepth 1 -type d -name "????????_??????*" | sort -r | head -n 1)
    if [ -z "$LATEST_FULL_BACKUP_DIR" ]; then
        error_exit "Aucune sauvegarde complète trouvée. Exécutez une sauvegarde complète d'abord."
    fi

    CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
    INCREMENTAL_BACKUP_PATH="${BACKUP_DIR}/incremental/$(basename "$LATEST_FULL_BACKUP_DIR")/inc_${CURRENT_DATE}"

    mkdir -p "$INCREMENTAL_BACKUP_PATH" || error_exit "Impossible de créer le répertoire de sauvegarde incrémentielle: $INCREMENTAL_BACKUP_PATH"

    log_message "INFO" "Sauvegarde incrémentielle depuis le timestamp de l'oplog: $LAST_OPLOG_TS"
    log_message "INFO" "Cible: $INCREMENTAL_BACKUP_PATH"

    local DUMP_COMMAND="mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} ${AUTH_OPTIONS} --oplog --oplogReplay --oplogReadPreference primary"

    if [ -n "$DB_NAME" ]; then
        DUMP_COMMAND="$DUMP_COMMAND --db $DB_NAME"
    fi

    # Exécution de mongodump pour la sauvegarde incrémentielle en utilisant le dernier timestamp de l'oplog
    log_message "INFO" "Exécution de la commande: $DUMP_COMMAND --oplogLimit ${LAST_OPLOG_TS} --out $INCREMENTAL_BACKUP_PATH"
    if ! eval "$DUMP_COMMAND --oplogLimit ${LAST_OPLOG_TS} --out $INCREMENTAL_BACKUP_PATH"; then
        error_exit "La sauvegarde incrémentielle a échoué. Vérifiez les logs pour plus de détails."
    fi

    # Récupérer le nouveau timestamp de l'oplog après la sauvegarde incrémentielle
    # Ce nouveau timestamp sera enregistré pour la prochaine sauvegarde incrémentielle
    NEW_OPLOG_TS=$(mongodump --host ${MONGO_HOST} --port ${MONGO_PORT} ${AUTH_OPTIONS} --oplog --oplogArbiterOnly --out /dev/null 2>&1 | grep "oplog: { ts: Timestamp" | awk -F'Timestamp(' '{print $2}' | awk -F', ' '{print $1}')

    if [ -z "$NEW_OPLOG_TS" ]; then
        log_message "WARNING" "Impossible de récupérer le nouveau timestamp de l'oplog. Le fichier de timestamp ne sera pas mis à jour."
    else
        echo "$NEW_OPLOG_TS" > "$OPLOG_TIMESTAMP_FILE"
        log_message "INFO" "Nouveau timestamp de l'oplog mis à jour: $NEW_OPLOG_TS"
    fi

    log_message "INFO" "Sauvegarde incrémentielle terminée avec succès dans $INCREMENTAL_BACKUP_PATH."
    rotate_backups "incremental" "$INCREMENTAL_BACKUP_RETENTION" "$LATEST_FULL_BACKUP_DIR"
}

# ===============================================
# Exécution du Script
# ===============================================

case "$1" in
    full)
        perform_full_backup
        ;;
    incremental)
        perform_incremental_backup
        ;;
    *)
        echo "Usage: $0 {full|incremental}"
        echo "  full       : Effectue une sauvegarde complète de MongoDB."
        echo "  incremental: Effectue une sauvegarde incrémentielle depuis la dernière sauvegarde."
        exit 1
        ;;
esac

log_message "INFO" "Script de sauvegarde MongoDB terminé."
exit 0
