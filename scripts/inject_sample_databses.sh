#!/bin/bash

# Script Bash pour cloner un dépôt Git et injecter des données dans MongoDB
# en utilisant l'outil mongoimport.

# --- Configuration des couleurs pour une meilleure lisibilité ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Fonction d'aide pour afficher l'utilisation du script ---
usage() {
    echo -e "${GREEN}Utilisation : $0 --repo-url <URL_DEPOT> --mongo-db <NOM_DB> --mongo-collection <NOM_COLLECTION> [--mongo-host <HOTE>] [--mongo-port <PORT>] [--mongo-user <UTILISATEUR>] [--mongo-password <MOT_DE_PASSE>]${NC}"
    echo ""
    echo "Arguments obligatoires :"
    echo "  --repo-url          L'URL du dépôt Git à cloner (ex: https://github.com/neelabalan/mongodb-sample-dataset)"
    echo "  --mongo-db          Le nom de la base de données MongoDB cible."
    echo "  --mongo-collection  Le nom de la collection MongoDB cible."
    echo ""
    echo "Arguments optionnels :"
    echo "  --mongo-host        L'hôte MongoDB (par défaut: localhost)"
    echo "  --mongo-port        Le port MongoDB (par défaut: 27017)"
    echo "  --mongo-user        Le nom d'utilisateur MongoDB (si authentification requise)"
    echo "  --mongo-password    Le mot de passe MongoDB (si authentification requise)"
    echo ""
    echo "Exemple :"
    echo "  $0 --repo-url https://github.com/neelabalan/mongodb-sample-dataset --mongo-db ma_base_de_donnees --mongo-collection ma_collection"
    echo "  $0 --repo-url https://github.com/neelabalan/mongodb-sample-dataset --mongo-db ma_base_de_donnees --mongo-collection ma_collection --mongo-user admin --mongo-password secret"
    exit 1
}

# --- Initialisation des variables avec des valeurs par défaut ---
REPO_URL=""
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_DB=""
MONGO_COLLECTION=""
MONGO_USER=""
MONGO_PASSWORD=""
TEMP_DIR=""

# --- Analyse des arguments de la ligne de commande ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --repo-url)
            REPO_URL="$2"
            shift
            ;;
        --mongo-host)
            MONGO_HOST="$2"
            shift
            ;;
        --mongo-port)
            MONGO_PORT="$2"
            shift
            ;;
        --mongo-db)
            MONGO_DB="$2"
            shift
            ;;
        --mongo-collection)
            MONGO_COLLECTION="$2"
            shift
            ;;
        --mongo-user)
            MONGO_USER="$2"
            shift
            ;;
        --mongo-password)
            MONGO_PASSWORD="$2"
            shift
            ;;
        *)
            echo -e "${RED}Erreur : Argument inconnu '$1'${NC}"
            usage
            ;;
    esac
    shift
done

# --- Vérification des arguments obligatoires ---
if [ -z "$REPO_URL" ] || [ -z "$MONGO_DB" ] || [ -z "$MONGO_COLLECTION" ]; then
    echo -e "${RED}Erreur : Les arguments --repo-url, --mongo-db et --mongo-collection sont obligatoires.${NC}"
    usage
fi

# --- Vérification de la présence des outils nécessaires ---
command -v git >/dev/null 2>&1 || { echo -e >&2 "${RED}Erreur : 'git' n'est pas installé. Veuillez l'installer et vous assurer qu'il est dans votre PATH.${NC}"; exit 1; }
command -v mongoimport >/dev/null 2>&1 || { echo -e >&2 "${RED}Erreur : 'mongoimport' n'est pas installé. Il fait partie des Outils de base de données MongoDB. Veuillez l'installer.${NC}"; exit 1; }

# --- Création d'un répertoire temporaire ---
TEMP_DIR=$(mktemp -d -t mongo_data_XXXXXX)
if [ $? -ne 0 ]; then
    echo -e "${RED}Erreur : Impossible de créer un répertoire temporaire.${NC}"
    exit 1
fi
echo -e "${YELLOW}Répertoire temporaire créé : $TEMP_DIR${NC}"

# --- Fonction de nettoyage à exécuter à la sortie du script ---
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Nettoyage du répertoire temporaire : $TEMP_DIR${NC}"
        rm -rf "$TEMP_DIR"
    fi
    echo -e "${GREEN}Script terminé.${NC}"
}
trap cleanup EXIT # Assure que la fonction cleanup est appelée à la sortie du script

# --- Clonage du dépôt Git ---
echo -e "${YELLOW}Clonage du dépôt ${REPO_URL} dans ${TEMP_DIR}...${NC}"
git clone "$REPO_URL" "$TEMP_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erreur lors du clonage du dépôt Git.${NC}"
    exit 1
fi
echo -e "${GREEN}Dépôt cloné avec succès.${NC}"

# --- Construction des options d'authentification MongoDB ---
MONGO_AUTH_OPTS=""
if [ -n "$MONGO_USER" ]; then
    MONGO_AUTH_OPTS="--username \"$MONGO_USER\""
    if [ -n "$MONGO_PASSWORD" ]; then
        MONGO_AUTH_OPTS="$MONGO_AUTH_OPTS --password \"$MONGO_PASSWORD\""
    fi
fi

# --- Définition du chemin des données dans le dépôt (peut être 'dataset' ou la racine) ---
DATA_PATH="$TEMP_DIR/dataset"
if [ ! -d "$DATA_PATH" ]; then
    echo -e "${YELLOW}Avertissement : Le sous-répertoire 'dataset' n'a pas été trouvé. Recherche de fichiers dans le répertoire racine du dépôt : $TEMP_DIR${NC}"
    DATA_PATH="$TEMP_DIR"
fi

FOUND_FILES=0

# --- Parcours des fichiers JSON et CSV et injection dans MongoDB ---
echo -e "${YELLOW}Recherche et injection des fichiers de données...${NC}"
find "$DATA_PATH" -type f \( -name "*.json" -o -name "*.csv" \) | while read -r FILEPATH; do
    FOUND_FILES=1
    FILENAME=$(basename "$FILEPATH")
    echo -e "${YELLOW}Traitement du fichier : $FILENAME${NC}"

    if [[ "$FILENAME" == *.json ]]; then
        # Pour les fichiers JSON, utilisez --jsonArray car de nombreux jeux de données sont des tableaux d'objets
        echo -e "${YELLOW}Injection du fichier JSON : $FILEPATH dans la collection $MONGO_COLLECTION...${NC}"
        mongoimport --host "$MONGO_HOST" --port "$MONGO_PORT" --db "$MONGO_DB" --collection "$MONGO_COLLECTION" \
                    --file "$FILEPATH" --jsonArray --type json $MONGO_AUTH_OPTS
        if [ $? -ne 0 ]; then
            echo -e "${RED}Erreur lors de l'importation du fichier JSON : $FILENAME${NC}"
        else
            echo -e "${GREEN}Fichier JSON $FILENAME importé avec succès.${NC}"
        fi
    elif [[ "$FILENAME" == *.csv ]]; then
        # Pour les fichiers CSV, utilisez --headerline pour que la première ligne soit traitée comme des en-têtes
        echo -e "${YELLOW}Injection du fichier CSV : $FILEPATH dans la collection $MONGO_COLLECTION...${NC}"
        mongoimport --host "$MONGO_HOST" --port "$MONGO_PORT" --db "$MONGO_DB" --collection "$MONGO_COLLECTION" \
                    --file "$FILEPATH" --type csv --headerline $MONGO_AUTH_OPTS
        if [ $? -ne 0 ]; then
            echo -e "${RED}Erreur lors de l'importation du fichier CSV : $FILENAME${NC}"
        else
            echo -e "${GREEN}Fichier CSV $FILENAME importé avec succès.${NC}"
        fi
    fi
done

if [ "$FOUND_FILES" -eq 0 ]; then
    echo -e "${YELLOW}Aucun fichier .json ou .csv trouvé dans le dépôt cloné pour l'injection.${NC}"
fi

# --- Fin du script ---