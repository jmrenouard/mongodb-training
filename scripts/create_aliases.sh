#!/bin/bash

# Nom du script : generate_mongo_aliases.sh
# Description : Génère des alias Bash pour se connecter facilement aux instances MongoDB,
#               incluant les identifiants directement dans les alias.
#               Met à jour automatiquement le fichier ~/.bashrc_mongodb et ~/.bashrc.
# Utilisation : bash ./generate_mongo_aliases.sh [USERNAME] [PASSWORD] [AUTH_DB]
# Exemple : bash ./generate_mongo_aliases.sh admin mySecurePass admin
#          (Si aucun argument n'est fourni, les alias seront générés sans authentification.)

USERNAME="$1"
PASSWORD="$2"
AUTH_DB="${3:-admin}" # Base de données d'authentification par défaut à 'admin'

AUTH_STRING=""
if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    AUTH_STRING="-u $USERNAME -p $PASSWORD --authenticationDatabase $AUTH_DB"
    echo "ATTENTION: Les mots de passe en clair dans les alias ou l'historique peuvent être un risque de sécurité."
    echo "Cette méthode est à utiliser avec prudence, idéalement pour le développement/test uniquement."
    echo ""
fi

BASHRC_MONGODB_FILE="$HOME/.bashrc_mongodb"
BASHRC_MAIN_FILE="$HOME/.bashrc"
CONFIG_DIR="/etc/mongod"

echo "--- Génération et mise à jour automatique des alias MongoDB ---"

# --- 1. Générer les alias dans un contenu temporaire ---
ALIAS_CONTENT=""
ALIAS_CONTENT+="# Alias générés automatiquement pour les instances MongoDB\n"
ALIAS_CONTENT+="# Date de génération: $(date)\n\n"

# Liste des outils MongoDB pour lesquels générer des alias
TOOLS=("mongosh" "mongodump" "mongoexport" "mongofiles" "mongoimport" "mongorestore" "mongostat" "mongotop")

# Parcourir tous les fichiers .conf dans le répertoire de configuration
for config_file in "$CONFIG_DIR"/*.conf; do
    # Vérifier si le fichier existe et est un fichier régulier
    if [ -f "$config_file" ]; then
        # Extraire le nom de l'instance du nom du fichier (ex: instance1 de instance1.conf)
        INSTANCE_NAME=$(basename "$config_file" .conf)

        # Extraire le port du fichier de configuration
        # Utilise grep pour trouver la ligne 'port:' et awk pour extraire le numéro après l'espace
        PORT=$(grep -E '^\s*port:' "$config_file" | awk '{print $2}')

        # Vérifier si le port a été trouvé
        if [ -z "$PORT" ]; then
            ALIAS_CONTENT+="# Avertissement: Impossible de trouver le port dans '$config_file'. Alias non générés pour cette instance.\n"
            continue # Passer à la prochaine itération
        fi

        ALIAS_CONTENT+="# Alias pour l'instance '$INSTANCE_NAME' sur le port '$PORT'\n"
        # Générer un alias pour chaque outil, incluant toujours la chaîne d'authentification
        for tool in "${TOOLS[@]}"; do
            ALIAS_NAME="${tool}_${INSTANCE_NAME}"
            ALIAS_CONTENT+="alias ${ALIAS_NAME}='${tool} --port ${PORT} ${AUTH_STRING}'\n"
        done
        ALIAS_CONTENT+="\n" # Ajouter une ligne vide pour une meilleure lisibilité
    fi
done

ALIAS_CONTENT+="# Fin des alias MongoDB\n"

# --- 2. Écrire le contenu généré dans ~/.bashrc_mongodb ---
echo "Mise à jour du fichier d'alias : ${BASHRC_MONGODB_FILE}..."
echo -e "$ALIAS_CONTENT" > "$BASHRC_MONGODB_FILE"
if [ $? -eq 0 ]; then
    echo "Fichier ${BASHRC_MONGODB_FILE} mis à jour avec succès."
else
    echo "Erreur: Impossible d'écrire dans ${BASHRC_MONGODB_FILE}. Vérifiez les permissions."
    exit 1
fi

# --- 3. S'assurer que ~/.bashrc_mongodb est sourcé dans ~/.bashrc ---
echo "Vérification et mise à jour de ${BASHRC_MAIN_FILE} pour sourcer ${BASHRC_MONGODB_FILE}..."
if ! grep -q "source ${BASHRC_MONGODB_FILE}" "$BASHRC_MAIN_FILE"; then
    echo "" >> "$BASHRC_MAIN_FILE"
    echo "# Source MongoDB aliases" >> "$BASHRC_MAIN_FILE"
    echo "source ${BASHRC_MONGODB_FILE}" >> "$BASHRC_MAIN_FILE"
    echo "Ligne 'source ${BASHRC_MONGODB_FILE}' ajoutée à ${BASHRC_MAIN_FILE}."
else
    echo "La ligne 'source ${BASHRC_MONGODB_FILE}' existe déjà dans ${BASHRC_MAIN_FILE}. Aucune action requise."
fi

echo ""
echo "--- Alias MongoDB mis à jour automatiquement ! ---"
echo "Pour que les nouveaux alias soient pris en compte dans votre session actuelle, exécutez :"
echo "  source ${BASHRC_MAIN_FILE}"
echo "Les alias seront également disponibles automatiquement dans les nouvelles sessions de terminal."
