#!/bin/bash

# Nom du script : setup_mongodb_mongos.sh
# Description : Initialise une nouvelle instance de routeur mongos pour un cluster shardé.
#               Vérifie/crée le script systemd de service template si nécessaire.
# Utilisation : sudo ./setup_mongodb_mongos.sh <NUMERO_MONGOS> <NOM_REPLICA_SET_CONFIG_SERVERS>/<MEMBRES_CONFIG_SERVERS>
# Exemple : sudo ./setup_mongodb_mongos.sh 1 configReplSet/config1:27019,config2:27019,config3:27019

# --- Vérification des privilèges root ---
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo."
  exit 1
fi

# --- Vérification des arguments ---
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: sudo $0 <NUMERO_MONGOS> <NOM_REPLICA_SET_CONFIG_SERVERS>/<MEMBRES_CONFIG_SERVERS>"
  echo "Exemple: sudo $0 1 configReplSet/config1:27019,config2:27019,config3:27019"
  echo "  <NUMERO_MONGOS> : Un numéro unique pour cette instance mongos (ex: 1, 2)."
  echo "  <NOM_REPLICA_SET_CONFIG_SERVERS>/<MEMBRES_CONFIG_SERVERS> : Le nom du replica set des serveurs de configuration"
  echo "                                                               suivi de la liste des membres (host:port) séparés par des virgules."
  exit 1
fi

MONGOS_NUMBER="$1"
CONFIG_DB_STRING="$2" # Ex: configReplSet/config1:27019,config2:27019,config3:27019

# Vérifie si le numéro de mongos est un entier positif
if ! [[ "$MONGOS_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  echo "Erreur: Le numéro de mongos doit être un entier positif."
  exit 1
fi

# --- Définition des variables ---
MONGOS_NAME="mongos${MONGOS_NUMBER}"
# Le port commence à 27020 pour mongos1, 27021 pour mongos2, etc.
# Choisir une plage de ports distincte pour éviter les conflits.
PORT=$((27020 + MONGOS_NUMBER - 1)) # -1 car MONGOS_NUMBER 1 doit donner 27020

# mongos n'a pas besoin d'un dbPath pour les données, mais il a besoin d'un répertoire pour les logs.
LOG_PATH="/var/log/mongodb/${MONGOS_NAME}"
CONFIG_DIR="/etc/mongod"
CONFIG_FILE="${CONFIG_DIR}/${MONGOS_NAME}.conf"
PID_FILE="/var/run/mongodb/${MONGOS_NAME}.pid" # PID spécifique à l'instance mongos
SYSTEMD_SERVICE_FILE="/etc/systemd/system/mongodb@.service"
KEYFILE_PATH="${CONFIG_DIR}/keyfile" # Le même fichier clé que pour les config servers et shards

echo "--- Initialisation de l'instance mongos : ${MONGOS_NAME} ---"
echo "Config DB : ${CONFIG_DB_STRING}"
echo "Port : ${PORT}"
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
# Service Systemd template pour MongoDB multi-instance (inclut mongod, arbitres, mongos)

[Unit]
Description=Serveur de base de données orienté document haute performance et sans schéma (%i)
After=network.target

[Service]
# L'utilisateur et le groupe sous lesquels mongod/mongos s'exécutera
User=mongodb
Group=mongodb

# Commande ExecStartPre pour nettoyer le fichier de socket si une instance précédente a planté.
# Elle extrait le port du fichier de configuration spécifique à l'instance.
ExecStartPre=/bin/sh -c 'SOCKET_PORT=$(grep -Po "^\s*port:\s*\K\d+" /etc/mongod/%i.conf 2>/dev/null); if [ -n "$SOCKET_PORT" ]; then rm -f /tmp/mongodb-${SOCKET_PORT}.sock; fi'

# Le chemin vers l'exécutable mongod ou mongos
# Note: Le service utilise le même template pour mongod et mongos.
# L'exécutable est déterminé par le fichier de configuration de l'instance.
# Pour mongos, le binaire est aussi /usr/bin/mongos
ExecStart=/usr/bin/mongos --config /etc/mongod/%i.conf

# Commande pour arrêter le processus proprement
ExecStop=/bin/kill -SIGTERM \$MAINPID

# Redémarrer le service si le processus se termine anormalement
Restart=always
RestartSec=5

# Limites de ressources
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
echo "1. Création des répertoires de logs pour mongos..."
mkdir -p "${LOG_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${LOG_PATH}."; exit 1; fi

mkdir -p "${CONFIG_DIR}" # S'assure que le répertoire de configuration existe
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer ${CONFIG_DIR}."; exit 1; fi

# Création du répertoire pour le fichier PID si ce n'est pas déjà fait
mkdir -p /var/run/mongodb/
if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer /var/run/mongodb/."; exit 1; fi
chown mongodb:mongodb /var/run/mongodb/
if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur /var/run/mongodb/."; exit 1; fi

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

# --- 2. Définition des permissions des répertoires de logs ---
echo "2. Définition des permissions pour l'utilisateur mongodb sur les répertoires de logs..."
chown -R mongodb:mongodb "${LOG_PATH}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de définir les permissions sur ${LOG_PATH}."; exit 1; fi

echo "Permissions définies avec succès."

# --- 3. Création du fichier de configuration de l'instance mongos ---
echo "3. Création du fichier de configuration : ${CONFIG_FILE}..."
cat <<EOF > "${CONFIG_FILE}"
# Configuration pour MongoDB mongos ${MONGOS_NUMBER} (${MONGOS_NAME})

systemLog:
  destination: file
  logAppend: true
  path: ${LOG_PATH}/mongos.log

processManagement:
  fork: false
  pidFilePath: ${PID_FILE}

net:
  port: ${PORT}
  bindIp: 0.0.0.0 # Écoute sur toutes les interfaces réseau

sharding:
  configDB: ${CONFIG_DB_STRING} # NOM DU REPLICA SET DES CONFIG SERVERS ET LEURS MEMBRES

security:
  # Décommenter la ligne ci-dessous pour activer l'authentification
  # authorization: enabled 
  # Décommenter la ligne ci-dessous si le replica set des config servers utilise un fichier clé
  # keyFile: ${KEYFILE_PATH}

# operationProfiling:
#   mode: slowOp
#   slowOpThresholdMs: 100
EOF

if [ $? -ne 0 ]; then echo "Erreur: Impossible de créer le fichier de configuration."; exit 1; fi
echo "Fichier de configuration créé avec succès."

# --- 4. Rechargement du daemon systemd ---
echo "4. Rechargement du daemon systemd..."
systemctl daemon-reload
if [ $? -ne 0 ]; then echo "Erreur: Impossible de recharger le daemon systemd."; exit 1; fi
echo "Daemon systemd rechargé."

# --- 5. Activation et démarrage du service ---
echo "5. Activation et démarrage du service mongodb@${MONGOS_NAME}..."
systemctl enable "mongodb@${MONGOS_NAME}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible d'activer le service."; exit 1; fi

systemctl start "mongodb@${MONGOS_NAME}"
if [ $? -ne 0 ]; then echo "Erreur: Impossible de démarrer le service. Vérifiez les logs avec 'journalctl -xeu mongodb@${MONGOS_NAME}'."; exit 1; fi
echo "Service mongodb@${MONGOS_NAME} démarré et activé."

# --- 6. Vérification du statut ---
echo "6. Vérification du statut du service..."
systemctl status "mongodb@${MONGOS_NAME}" --no-pager

echo ""
echo "--- Initialisation de l'instance mongos ${MONGOS_NAME} terminée ! ---"
echo ""
echo "--- Étape SUIVANTE et CRUCIALE : Ajout des shards et activation du sharding ---"
echo "Connectez-vous au shell MongoDB via cette instance mongos et ajoutez vos shards :"
echo "  mongosh --port ${PORT}"
echo "Puis, dans le shell, pour chaque shard (replica set) :"
echo "  sh.addShard(\"NOM_REPLICA_SET_DU_SHARD/membre1:port1,membre2:port2,...\")"
echo ""
echo "Exemple pour ajouter un shard nommé 'shardReplSet' avec 3 membres :"
echo "  sh.addShard(\"shardReplSet/shard1:27017,shard2:27017,shard3:27017\")"
echo ""
echo "Après avoir ajouté vos shards, vous pouvez activer le sharding sur une base de données :"
echo "  sh.enableSharding(\"nomDeVotreBaseDeDonnees\")"
echo ""
echo "Puis sharder une collection :"
echo "  sh.shardCollection(\"nomDeVotreBaseDeDonnees.nomDeVotreCollection\", { \"champDeCleDeShard\": 1 })"
echo ""
echo "N'oubliez pas de configurer un pare-feu si l'instance mongos est exposée sur le réseau."
echo "Vous pouvez vérifier l'état du sharding avec :"
echo "  sh.status()"
echo ""
echo "Installation de l'instance mongos ${MONGOS_NAME} terminée !"
echo "Vous pouvez vous connecter avec : mongosh --port ${PORT}"
echo "N'oubliez pas de configurer un pare-feu si l'instance mongos est exposée sur le réseau."
echo "Pour vérifier les logs de l'instance mongos,