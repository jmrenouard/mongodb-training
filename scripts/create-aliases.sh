#!/bin/bash

# Nom du script : generate_mongo_aliases.sh
# Description : Génère des alias Bash pour se connecter facilement aux instances MongoDB.
# Utilisation : bash ./generate_mongo_aliases.sh [USERNAME] [PASSWORD] [AUTH_DB]
# Exemple : bash ./generate_mongo_aliases.sh admin mySecurePass admin
#          (Si aucun argument n'est fourni, les alias seront générés sans authentification.)

USERNAME="$1"
PASSWORD="$2"
AUTH_DB="${3:-admin}" # Base de données d'authentification par défaut à 'admin'

AUTH_STRING=""
if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    AUTH_STRING="-u $USERNAME -p $PASSWORD --authenticationDatabase $AUTH_DB"
    echo "# ATTENTION: Les mots de passe en clair dans les alias ou l'historique peuvent être un risque de sécurité."
    echo "# Pour la production, considérez d'autres méthodes comme les variables d'environnement ou le fichier ~/.mongoshrc.js pour mongosh."
    echo ""
fi

echo "# Alias générés automatiquement pour les instances MongoDB"
echo "# Pour utiliser ces alias :"
echo "# 1. Copiez le contenu de ce bloc dans votre fichier ~/.bashrc ou ~/.bash_aliases."
echo "# 2. Enregistrez le fichier."
echo "# 3. Exécutez 'source ~/.bashrc' (ou 'source ~/.bash_aliases') dans votre terminal."
echo ""

CONFIG_DIR="/etc/mongod"
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
            echo "# Avertissement: Impossible de trouver le port dans '$config_file'. Alias non générés pour cette instance."
            continue # Passer à la prochaine itération
        fi

        echo "# Alias pour l'instance '$INSTANCE_NAME' sur le port '$PORT'"
        # Générer un alias pour chaque outil
        for tool in "${TOOLS[@]}"; do
            ALIAS_NAME="${tool}_${INSTANCE_NAME}"
            echo "alias ${ALIAS_NAME}='${tool} --port ${PORT} ${AUTH_STRING}'"
        done
        echo "" # Ajouter une ligne vide pour une meilleure lisibilité
    fi
done

echo "# Fin des alias MongoDB"
