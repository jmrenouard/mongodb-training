#!/bin/bash

# Nom du script : uninstall_mongodb_instance.sh
# Description : Désinstalle une instance MongoDB spécifique en fonction de son numéro.
# Utilisation : sudo ./uninstall_mongodb_instance.sh <NUMERO_INSTANCE>
# Exemple : sudo ./uninstall_mongodb_instance.sh 1 (pour instance1)

# --- Vérification des privilèges root ---
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo."
  exit 1
fi

# --- Vérification de l'argument ---
if [ -z "$1" ]; then
  echo "Usage: sudo $0 <NUMERO_INSTANCE>"
  echo "Exemple: sudo $0 1"
  exit 1
fi

INSTANCE_NUMBER="$1"

# Vérifie si le numéro d'instance est un entier positif
if ! [[ "$INSTANCE_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  echo "Erreur: Le numéro d'instance doit être un entier positif."
  exit 1
fi

# --- Définition des variables ---
INSTANCE_NAME="instance${INSTANCE_NUMBER}"
DB_PATH="/var/lib/mongodb/${INSTANCE_NAME}"
LOG_PATH="/var/log/mongodb/${INSTANCE_NAME}"
CONFIG_FILE="/etc/mongod/${INSTANCE_NAME}.conf"
SYSTEMD_SERVICE_NAME="mongodb@${INSTANCE_NAME}"

echo "--- Désinstallation de l'instance MongoDB : ${INSTANCE_NAME} ---"
echo "Les éléments suivants seront supprimés :"
echo "  - Service Systemd : ${SYSTEMD_SERVICE_NAME}"
echo "  - Fichier de configuration : ${CONFIG_FILE}"
echo "  - Répertoire de données : ${DB_PATH}"
echo "  - Répertoire de logs : ${LOG_PATH}"
echo ""

# --- Demande de confirmation ---
read -p "Êtes-vous sûr de vouloir désinstaller l'instance '${INSTANCE_NAME}' ? (oui/non) " -n 3 -r
echo # (ajoute un retour à la ligne après la saisie)
if [[ ! "$REPLY" =~ ^oui$ ]]; then
    echo "Désinstallation annulée."
    exit 0
fi

echo "Confirmation reçue. Début de la désinstallation..."

# --- 1. Arrêt et désactivation du service Systemd ---
echo "1. Arrêt et désactivation du service Systemd '${SYSTEMD_SERVICE_NAME}'..."
if systemctl is-active --quiet "${SYSTEMD_SERVICE_NAME}"; then
    systemctl stop "${SYSTEMD_SERVICE_NAME}"
    if [ $? -ne 0 ]; then echo "Avertissement: Impossible d'arrêter le service. Tentative de désactivation et de suppression quand même."; fi
else
    echo "Le service '${SYSTEMD_SERVICE_NAME}' n'est pas actif."
fi

if systemctl is-enabled --quiet "${SYSTEMD_SERVICE_NAME}"; then
    systemctl disable "${SYSTEMD_SERVICE_NAME}"
    if [ $? -ne 0 ]; then echo "Avertissement: Impossible de désactiver le service."; fi
else
    echo "Le service '${SYSTEMD_SERVICE_NAME}' n'est pas activé au démarrage."
fi
echo "Service Systemd arrêté et désactivé (si existant)."

# --- 2. Suppression du fichier de configuration ---
echo "2. Suppression du fichier de configuration '${CONFIG_FILE}'..."
if [ -f "${CONFIG_FILE}" ]; then
    rm -f "${CONFIG_FILE}"
    if [ $? -ne 0 ]; then echo "Erreur: Impossible de supprimer le fichier de configuration. Vérifiez les permissions."; exit 1; fi
    echo "Fichier de configuration supprimé."
else
    echo "Le fichier de configuration '${CONFIG_FILE}' n'existe pas."
fi

# --- 3. Suppression des répertoires de données et de logs ---
echo "3. Suppression du répertoire de données '${DB_PATH}'..."
if [ -d "${DB_PATH}" ]; then
    rm -rf "${DB_PATH}"
    if [ $? -ne 0 ]; then echo "Erreur: Impossible de supprimer le répertoire de données. Vérifiez les permissions."; exit 1; fi
    echo "Répertoire de données supprimé."
else
    echo "Le répertoire de données '${DB_PATH}' n'existe pas."
fi

echo "Suppression du répertoire de logs '${LOG_PATH}'..."
if [ -d "${LOG_PATH}" ]; then
    rm -rf "${LOG_PATH}"
    if [ $? -ne 0 ]; then echo "Erreur: Impossible de supprimer le répertoire de logs. Vérifiez les permissions."; exit 1; fi
    echo "Répertoire de logs supprimé."
else
    echo "Le répertoire de logs '${LOG_PATH}' n'existe pas."
fi

# --- 4. Rechargement du daemon systemd ---
echo "4. Rechargement du daemon systemd..."
systemctl daemon-reload
if [ $? -ne 0 ]; then echo "Erreur: Impossible de recharger le daemon systemd."; exit 1; fi
echo "Daemon systemd rechargé."

echo ""
echo "--- Désinstallation de l'instance '${INSTANCE_NAME}' terminée ! ---"
echo "L'instance MongoDB a été supprimée de votre système."
echo "Si vous souhaitez réinstaller cette instance, vous devrez créer un nouveau fichier de configuration et un nouveau service systemd."