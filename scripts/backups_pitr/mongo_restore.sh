#!/bin/bash

# ===============================================
# Configuration de la Restauration MongoDB
# ===============================================

# Répertoire de base des sauvegardes (doit correspondre à celui du script de sauvegarde)
BACKUP_BASE_DIR="/data/mongodb_backups"

# Hôte et Port MongoDB cible pour la restauration
MONGO_RESTORE_HOST="localhost"
MONGO_RESTORE_PORT="27017"

# Optionnel : Nom d'utilisateur et mot de passe si authentification activée sur le serveur cible
# MONGO_RESTORE_USER="your_mongo_restore_user"
# MONGO_RESTORE_PASS="your_mongo_restore_password"

# Fichier de log pour la restauration
LOG_FILE="${BACKUP_BASE_DIR}/mongodb_restore.log"

# ===============================================
# Structure des Répertoires de Sauvegarde (Rappel)
# ===============================================
# Le script de sauvegarde précédent génère la structure suivante :
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
# Ce script de restauration utilisera cette structure pour trouver les sauvegardes
# complètes et incrémentielles associées à la sauvegarde complète spécifiée.

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

# Vérifier si mongorestore est installé
command -v mongorestore >/dev/null 2>&1 || error_exit "mongorestore n'est pas trouvé. Veuillez l'installer."

# Créer le fichier de log si inexistant
touch "$LOG_FILE" || error_exit "Impossible de créer le fichier de log."

# Options d'authentification pour mongorestore
AUTH_OPTIONS=""
# if [ -n "$MONGO_RESTORE_USER" ] && [ -n "$MONGO_RESTORE_PASS" ]; then
#     AUTH_OPTIONS="--username $MONGO_RESTORE_USER --password $MONGO_RESTORE_PASS"
# fi

# Vérifier les arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <FULL_BACKUP_TIMESTAMP_DIR>"
    echo "Exemple: $0 20240707_103000"
    echo "  <FULL_BACKUP_TIMESTAMP_DIR> est le nom du répertoire de la sauvegarde complète (ex: 20240707_103000)"
    exit 1
fi

FULL_BACKUP_TIMESTAMP_DIR="$1"
FULL_BACKUP_PATH="${BACKUP_BASE_DIR}/full/${FULL_BACKUP_TIMESTAMP_DIR}"
INCREMENTAL_BASE_PATH="${BACKUP_BASE_DIR}/incremental/${FULL_BACKUP_TIMESTAMP_DIR}"

# Vérifier l'existence du répertoire de sauvegarde complète
if [ ! -d "$FULL_BACKUP_PATH" ]; then
    error_exit "Le répertoire de sauvegarde complète '$FULL_BACKUP_PATH' n'existe pas."
fi

log_message "INFO" "Démarrage de la restauration MongoDB."
log_message "INFO" "Restauration de la sauvegarde complète: $FULL_BACKUP_PATH"

# 1. Restauration de la sauvegarde complète
# L'option --drop supprime toutes les collections existantes dans la base de données cible avant la restauration.
# Soyez TRES PRUDENT avec cette option en production.
RESTORE_FULL_COMMAND="mongorestore --host ${MONGO_RESTORE_HOST} --port ${MONGO_RESTORE_PORT} ${AUTH_OPTIONS} --drop ${FULL_BACKUP_PATH}"

log_message "INFO" "Exécution de la commande: $RESTORE_FULL_COMMAND"
if ! eval "$RESTORE_FULL_COMMAND"; then
    error_exit "La restauration de la sauvegarde complète a échoué. Vérifiez les logs pour plus de détails."
fi
log_message "INFO" "Restauration de la sauvegarde complète terminée avec succès."

# 2. Application des sauvegardes incrémentielles (oplog dumps)
# Ces dumps contiennent les opérations qui se sont produites depuis la dernière sauvegarde.
if [ -d "$INCREMENTAL_BASE_PATH" ]; then
    log_message "INFO" "Application des sauvegardes incrémentielles depuis: $INCREMENTAL_BASE_PATH"

    # Trouver et trier les dumps d'oplog incrémentiels par ordre chronologique
    # Le nom des répertoires incrémentiels est au format inc_YYYYMMDD_HHmmss, ce qui assure le tri correct.
    INCREMENTAL_DUMPS=$(find "$INCREMENTAL_BASE_PATH" -maxdepth 1 -type d -name "inc_????????_??????*" | sort)

    if [ -z "$INCREMENTAL_DUMPS" ]; then
        log_message "WARNING" "Aucune sauvegarde incrémentielle trouvée pour la sauvegarde complète de référence: $FULL_BACKUP_TIMESTAMP_DIR."
    else
        for INC_DIR in $INCREMENTAL_DUMPS; do
            OPLOG_FILE="${INC_DIR}/oplog.bson"
            if [ -f "$OPLOG_FILE" ]; then
                log_message "INFO" "Application du dump d'oplog incrémentiel: $OPLOG_FILE"
                # L'option --oplogReplay applique les opérations de l'oplog au serveur MongoDB.
                RESTORE_INC_COMMAND="mongorestore --host ${MONGO_RESTORE_HOST} --port ${MONGO_RESTORE_PORT} ${AUTH_OPTIONS} --oplogReplay $OPLOG_FILE"

                log_message "INFO" "Exécution de la commande: $RESTORE_INC_COMMAND"
                if ! eval "$RESTORE_INC_COMMAND"; then
                    error_exit "L'application du dump d'oplog '$OPLOG_FILE' a échoué. La restauration est incomplète."
                fi
                log_message "INFO" "Dump d'oplog '$OPLOG_FILE' appliqué avec succès."
            else
                log_message "WARNING" "Le fichier oplog.bson est introuvable dans '$INC_DIR'. Cette sauvegarde incrémentielle sera ignorée."
            fi
        done
        log_message "INFO" "Toutes les sauvegardes incrémentielles ont été appliquées."
    fi
else
    log_message "INFO" "Aucun répertoire de sauvegardes incrémentielles trouvé pour la base complète: $FULL_BACKUP_TIMESTAMP_DIR."
fi

log_message "INFO" "Script de restauration MongoDB terminé."
exit 0
