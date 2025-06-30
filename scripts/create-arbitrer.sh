#!/bin/bash

# Nom du script : setup_mongodb_arbiter.sh
# Description : Initialise une nouvelle instance d'arbitre MongoDB pour un replica set donné.
#               Vérifie/crée le script systemd de service template si nécessaire.
# Utilisation : sudo ./setup_mongodb_arbiter.sh <NUMERO_ARBITRE> <NOM_REPLICA_SET>
# Exemple : sudo ./setup_mongodb_arbiter.sh 1 rs0 (pour arbiter1 sur le replica set 'rs0')

# --- Vérification des privilèges root ---
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo."
  exit 1
fi

# --- Vérification des arguments ---
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: sudo $0 <NUMERO_ARBITRE> <NOM_REPLICA_SET>"
  echo "Exemple: sudo $0 1 rs0"
  exit 1
fi

ARBITER_NUMBER="$1"
REPLICA_SET_NAME="$2"

# Vérifie si le numéro d'arbitre est un entier positif
if ! [[ "$ARBITER_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  echo "Erreur: Le numéro d'arbitre doit être un entier positif."
  exit 1
fi

# --- Définition des variables ---
ARBITER_NAME="arbiter${ARBITER_NUMBER}"
# Le port commence à 28000 pour arbiter0, 28001 pour arbiter1, etc.
# Nous utilisons 28000 comme base pour éviter les conflits avec les instances de données (2701x).
PORT=$((28000 + ARBITER_NUMBER))
DB_PATH="/var/lib/mongodb/${ARBITER_NAME}" # dbPath est requis même pour un arbitre
LOG_PATH="/var/log/mongodb/${ARBITER_NAME}"
CONFIG_DIR="/etc/mongod"
CONFIG_FILE="${CONFIG_DIR}/${ARBITER_NAME}.conf"
PID_FILE="${DB_PATH}/mongod.pid"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/mongodb@.service"
KEYFILE_PATH="${CONFIG_DIR}/keyfile" # Le même fichier clé que pour les autres membres du replica set

echo "--- Initialisation de l'arbitre MongoDB : ${ARBITER_NAME} ---"
echo "Replica Set : ${REPLICA_SET_NAME}"
echo "Port : ${PORT}"
echo "Chemin des données : ${DB_PATH}"
echo "Chemin des logs : ${LOG_PATH}"
echo "Fichier de configuration : ${CONFIG_FILE}"
echo "Fichier de service Systemd : ${SYSTEMD_SERVICE_FILE}"
echo "Fichier clé : ${KEYFILE_PATH}"

# --- 0. Vérification et création du fichier de service systemd template ---
echo "0. Vérification et création du fichier de service systemd template (${SYSTEMD_SERVICE_FILE})..."
if [ ! -f "${SYSTEMD_SERVICE_FILE}" ]; then
  echo "Le fichier de service systemd template n'existe pas. Création..."
  cat <<EOF > "${SYSTEMD_SERVICE_FILE}"
# /etc/systemd/system/mongodb@.service
# Service Systemd template pour MongoDB multi-instance (inclut les arbitres)

[Unit]
Description=Serveur de base de données orienté document haute performance et sans schéma (%i)
After=network.target

[Service]
# L'utilisateur et le groupe sous lesquels mongod s'exécutera
User=mongodb
Group=mongodb

# Commande ExecStartPre pour nettoyer le fichier de socket si une instance précédente a planté.
# Elle extrait le port du fichier de configuration spécifique à l'instance.
ExecStartPre=/bin/sh -c 'SOCKET_PORT=$(grep -Po "^\s*port:\s*\K\d+" /etc/mongod/%i.conf 2>/dev/null); if [ -n "$SOCKET_PORT" ]; then rm -f /tmp/mongodb-${SOCKET_PORT}.sock; fi'

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
echo "1. Création des répertoires de données et de logs pour l'arbitre..."
mkdir -p "${DB_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${DB_PATH}."; exit 1; fi

mkdir -p "${LOG_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${LOG_PATH}."; exit 1; fi

mkdir -p "${CONFIG_DIR}" # S'assure que le répertoire de configuration existe
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${CONFIG_DIR}."; exit 1; fi

echo "Répertoires créés avec succès."

# --- 1.5. Vérification et création du fichier clé (keyFile) ---
echo "1.5. Vérification et création du fichier clé MongoDB (${KEYFILE_PATH})..."
if [ ! -f "${KEYFILE_PATH}" ]; then
  echo "Le fichier clé n'existe pas. Création d'un nouveau fichier clé..."
  # Génère une chaîne aléatoire de 1024 caractères (base64 encodé)
  openssl rand -base64 756 > "${KEYFILE_PATH}"
  if [ $? -ne 0 ]; then echo "Erreur: Impossible de générer le fichier clé. Assurez-vous qu'openssl est installé."; exit 1; fi

  # Définit les permissions strictes (lecture/écriture pour le propriétaire)
  chmod 600 "${KEYFILE_PATH}"
  if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur le fichier clé."; exit 1; fi

  # Définit la propriété à l'utilisateur mongodb
  chown mongodb:mongodb "${KEYFILE_PATH}"
  if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir la propriété sur le fichier clé."; exit 1; fi
  echo "Fichier clé créé et sécurisé avec succès."
else
  echo "Le fichier clé existe déjà. Aucune action requise."
fi

# --- 2. Définition des permissions des répertoires de données/logs ---
echo "2. Définition des permissions pour l'utilisateur mongodb sur les répertoires de données et de logs..."
chown -R mongodb:mongodb "${DB_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur ${DB_PATH}."; exit 1; fi

chown -R mongodb:mongodb "${LOG_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur ${LOG_PATH}."; exit 1; fi

echo "Permissions définies avec succès."

# --- 3. Création du fichier de configuration de l'arbitre ---
echo "3. Création du fichier de configuration : ${CONFIG_FILE}..."
cat <<EOF > "${CONFIG_FILE}"
# Configuration pour MongoDB Arbitre ${ARBITER_NUMBER} (${ARBITER_NAME})

systemLog:
  destination: file
  logAppend: true
  path: ${LOG_PATH}/mongod.log

storage:
  dbPath: ${DB_PATH}
  # La journalisation est activée par défaut depuis MongoDB 3.0 et cette option n'est plus nécessaire.
  # journal:
  #   enabled: true 

processManagement:
  fork: false
  pidFilePath: ${PID_FILE}

net:
  port: ${PORT}
  bindIp: 0.0.0.0 # Écoute sur toutes les interfaces réseau

security:
  # Décommenter la ligne ci-dessous pour activer l'authentification
  # authorization: enabled 
  # Décommenter la ligne ci-dessous et configurer un replica set pour utiliser un fichier clé
  # keyFile: ${KEYFILE_PATH}

replication:
  replSetName: ${REPLICA_SET_NAME} # NOM DU REPLICA SET - DÉCOMMENTÉ POUR UN ARBITRE

# operationProfiling:
#   mode: slowOp
#   slowOpThresholdMs: 100

# sharding:
#   clusterRole: configsvr
#   clusterRole: shardsvr
EOF

if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer le fichier de configuration."; exit 1; fi
echo "Fichier de configuration créé avec succès."

# --- 4. Rechargement du daemon systemd ---
echo "4. Rechargement du daemon systemd..."
systemctl daemon-reload
if [ $? -ne 0 ]; then echo "Erreur: Impossible de recharger le daemon systemd."; exit 1; fi
echo "Daemon systemd rechargé."

# --- 5. Activation et démarrage du service ---
echo "5. Activation et démarrage du service ${SYSTEMD_SERVICE_NAME}..."
systemctl enable "${SYSTEMD_SERVICE_NAME}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible d'activer le service."; exit 1; fi

systemctl start "${SYSTEMD_SERVICE_NAME}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de démarrer le service. Vérifiez les logs avec 'journalctl -xeu ${SYSTEMD_SERVICE_NAME}'."; exit 1; fi
echo "Service ${SYSTEMD_SERVICE_NAME} démarré et activé."

# --- 6. Vérification du statut ---
echo "6. Vérification du statut du service..."
systemctl status "${SYSTEMD_SERVICE_NAME}" --no-pager

echo ""
echo "--- Initialisation de l'arbitre ${ARBITER_NAME} terminée ! ---"
echo ""
echo "--- Étape SUIVANTE et CRUCIALE : Ajout de l'arbitre au Replica Set ---"
echo "Connectez-vous au shell MongoDB sur le nœud primaire de votre replica set (${REPLICA_SET_NAME}) et exécutez la commande suivante :"
echo "  mongosh --port <PORT_DU_PRIMAIRE> -u <UTILISATEUR_ADMIN> -p <MOT_DE_PASSE_ADMIN> --authenticationDatabase admin"
echo "Puis, dans le shell :"
echo "  rs.addArb(\"$(hostname -I | awk '{print $1}'):${PORT}\")"
echo ""
echo "Vérifiez que l'arbitre est bien ajouté avec : rs.status()"
echo "N'oubliez pas de configurer un pare-feu si l'arbitre est exposé sur le réseau."
