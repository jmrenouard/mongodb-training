#!/bin/bash

# Nom du script : setup_mongodb_instance.sh
# Description : Initialise une nouvelle instance MongoDB avec un numéro donné,
#               et vérifie/crée le script systemd de service template si nécessaire.
# Utilisation : sudo ./setup_mongodb_instance.sh <NUMERO_INSTANCE>
# Exemple : sudo ./setup_mongodb_instance.sh 1 (pour instance1, port 27017)
#           sudo ./setup_mongodb_instance.sh 2 (pour instance2, port 27018)

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
# Le port commence à 27017 pour instance1, 27018 pour instance2, etc.
PORT=$((27016 + INSTANCE_NUMBER))
DB_PATH="/var/lib/mongodb/${INSTANCE_NAME}"
LOG_PATH="/var/log/mongodb/${INSTANCE_NAME}"
CONFIG_DIR="/etc/mongod"
CONFIG_FILE="${CONFIG_DIR}/${INSTANCE_NAME}.conf"
PID_FILE="${DB_PATH}/mongod.pid" # PID spécifique à l'instance
SYSTEMD_SERVICE_FILE="/etc/systemd/system/mongodb@.service"

echo "--- Initialisation de l'instance MongoDB : ${INSTANCE_NAME} ---"
echo "Port : ${PORT}"
echo "Chemin des données : ${DB_PATH}"
echo "Chemin des logs : ${LOG_PATH}"
echo "Fichier de configuration : ${CONFIG_FILE}"
echo "Fichier de service Systemd : ${SYSTEMD_SERVICE_FILE}"

# --- 0. Vérification et création du fichier de service systemd template ---
echo "0. Vérification et création du fichier de service systemd template (${SYSTEMD_SERVICE_FILE})..."
if [ ! -f "${SYSTEMD_SERVICE_FILE}" ]; then
  echo "Le fichier de service systemd template n'existe pas. Création..."
  cat <<EOF > "${SYSTEMD_SERVICE_FILE}"
# /etc/systemd/system/mongodb@.service
# Service Systemd template pour MongoDB multi-instance

[Unit]
Description=Serveur de base de données orienté document haute performance et sans schéma (%i)
After=network.target

[Service]
# L'utilisateur et le groupe sous lesquels mongod s'exécutera
User=mongodb
Group=mongodb

# Le chemin vers l'exécutable mongod
ExecStart=/usr/bin/mongod --config /etc/mongod/%i.conf

# Commande pour arrêter mongod proprement
ExecStop=/bin/kill -SIGTERM \$MAINPID

# Redémarrer le service si le processus se termine anormalement
Restart=always
RestartSec=5

# Limites de ressources pour mongod
LimitNOFILE=64000
LimitNPROC=64000
LimitFSIZE=infinity

# Sortie standard et erreur standard vers le journal systemd
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
  if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer le fichier de service systemd template."; exit 1; fi
  echo "Fichier de service systemd template créé avec succès."
else
  echo "Le fichier de service systemd template existe déjà. Aucune action requise."
fi


# --- 1. Création des répertoires ---
echo "1. Création des répertoires de données et de logs..."
mkdir -p "${DB_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${DB_PATH}."; exit 1; fi

mkdir -p "${LOG_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${LOG_PATH}."; exit 1; fi

mkdir -p "${CONFIG_DIR}" # S'assure que le répertoire de configuration existe
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${CONFIG_DIR}."; exit 1; fi

echo "Répertoires créés avec succès."

# --- 2. Définition des permissions ---
echo "2. Définition des permissions pour l'utilisateur mongodb..."
chown -R mongodb:mongodb "${DB_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur ${DB_PATH}."; exit 1; fi

chown -R mongodb:mongodb "${LOG_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur ${LOG_PATH}."; exit 1; fi

echo "Permissions définies avec succès."

# --- 3. Création du fichier de configuration de l'instance ---
echo "3. Création du fichier de configuration : ${CONFIG_FILE}..."
cat <<EOF > "${CONFIG_FILE}"
# Configuration pour MongoDB Instance ${INSTANCE_NUMBER} (${INSTANCE_NAME})

systemLog:
  destination: file
  logAppend: true
  path: ${LOG_PATH}/mongod.log

storage:
  dbPath: ${DB_PATH}
  journal:
    enabled: true

processManagement:
  fork: false
  pidFilePath: ${PID_FILE}

net:
  port: ${PORT}
  bindIp: 0.0.0.0 # Écoute sur toutes les interfaces réseau

security:
  # Décommenter la ligne ci-dessous pour activer l'authentification
  # authorization: enabled 

# operationProfiling:
#   mode: slowOp
#   slowOpThresholdMs: 100

# replication:
#   replSetName: rs${INSTANCE_NUMBER} # Décommenter et configurer pour un replica set

# sharding:
#   clusterRole: configsvr # Décommenter et configurer si c'est un serveur de configuration
#   clusterRole: shardsvr # Décommenter et configurer si c'est un shard
EOF

if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer le fichier de configuration."; exit 1; fi
echo "Fichier de configuration créé avec succès."

# --- 4. Rechargement du daemon systemd ---
echo "4. Rechargement du daemon systemd..."
systemctl daemon-reload
if [ $? -ne 0 ]; then echo "Erreur: Impossible de recharger le daemon systemd."; exit 1; fi
echo "Daemon systemd rechargé."

# --- 5. Activation et démarrage du service ---
echo "5. Activation et démarrage du service mongodb@${INSTANCE_NAME}..."
systemctl enable "mongodb@${INSTANCE_NAME}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible d'activer le service."; exit 1; fi

systemctl start "mongodb@${INSTANCE_NAME}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de démarrer le service. Vérifiez les logs avec 'journalctl -xeu mongodb@${INSTANCE_NAME}'."; exit 1; fi
echo "Service mongodb@${INSTANCE_NAME} démarré et activé."

# --- 6. Vérification du statut ---
echo "6. Vérification du statut du service..."
systemctl status "mongodb@${INSTANCE_NAME}" --no-pager

echo ""
echo "--- Initialisation de l'instance ${INSTANCE_NAME} terminée ! ---"
echo "Vous pouvez vous connecter avec : mongosh --port ${PORT}"
echo "N'oubliez pas de configurer un pare-feu si l'instance est exposée sur le réseau."
echo "Pour plus d'informations sur les outils, consultez la documentation MongoDB."