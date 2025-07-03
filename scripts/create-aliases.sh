#!/bin/bash

# Nom du script : generate_mongo_aliases.sh
# Description : Génère des alias Bash pour se connecter facilement aux instances MongoDB,
#               et gère la création du fichier ~/.mongoshrc.js si nécessaire,
#               en y pré-remplissant un exemple de connexion pour chaque instance.
# Utilisation : bash ./generate_mongo_aliases.sh [USERNAME] [PASSWORD] [AUTH_DB]
# Exemple : bash ./generate_mongo_aliases.sh admin mySecurePass admin
#          (Si aucun argument n'est fourni, les exemples dans ~/.mongoshrc.js utiliseront des placeholders.)

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

# --- 1. Génération/Vérification du fichier ~/.mongoshrc.js ---
MONGOSHRC_FILE="$HOME/.mongoshrc.js"
echo "--- Gestion du fichier ~/.mongoshrc.js ---"
if [ ! -f "$MONGOSHRC_FILE" ]; then
    echo "Le fichier ~/.mongoshrc.js n'existe pas. Création..."

    # Définir les valeurs par défaut ou utiliser celles fournies pour les exemples
    M_USERNAME="${USERNAME:-votre_utilisateur}"
    M_PASSWORD="${PASSWORD:-votre_mot_de_passe}"
    M_AUTH_DB="${AUTH_DB:-admin}"
    M_HOST="127.0.0.1" # L'utilisateur a demandé 'localhost', qui se traduit par 127.0.0.1

    # Début du contenu du fichier .mongoshrc.js
    MONGOSHRC_CONTENT="// Fichier de configuration pour mongosh
// Pour plus d'informations, voir : https://www.mongodb.com/docs/mongodb-shell/reference/shell-configuration/

// Cet exemple de connexion est généré automatiquement pour chaque instance détectée.
// Il est recommandé de le personnaliser avec vos propres identifiants sécurisés.

"
    CONFIG_DIR="/etc/mongod"
    # Parcourir tous les fichiers .conf pour générer les connexions mongosh
    for config_file in "$CONFIG_DIR"/*.conf; do
        if [ -f "$config_file" ]; then
            INSTANCE_NAME=$(basename "$config_file" .conf)
            PORT=$(grep -E '^\s*port:' "$config_file" | awk '{print $2}')

            if [ -n "$PORT" ]; then
                MONGOSHRC_CONTENT+="const ${INSTANCE_NAME}Conn = {
  host: \"${M_HOST}\",
  port: ${PORT},
  username: \"${M_USERNAME}\",
  password: \"${M_PASSWORD}\",
  authenticationDatabase: \"${M_AUTH_DB}\"
};

// Pour vous connecter à ${INSTANCE_NAME} : connect(${INSTANCE_NAME}Conn);

"
            fi
        fi
    done

    MONGOSHRC_CONTENT+="// Vous pouvez ajouter des fonctions personnalisées ici.
// Exemple : une fonction pour lister les bases de données
// function listDatabases() {
//   return db.adminCommand({ listDatabases: 1 });
// }
"
    echo "$MONGOSHRC_CONTENT" > "$MONGOSHRC_FILE"
    chmod 600 "$MONGOSHRC_FILE" # S'assurer que seul l'utilisateur peut lire/écrire
    echo "Fichier ~/.mongoshrc.js créé avec succès. Il contient des exemples de connexion pour chaque instance."
    echo "Veuillez le modifier pour ajuster les identifiants si nécessaire."
else
    echo "Le fichier ~/.mongoshrc.js existe déjà. Aucune action requise."
fi
echo ""

echo "--- Alias générés automatiquement pour les instances MongoDB ---"
echo "# Pour utiliser ces alias :"
echo "# 1. Copiez le contenu de ce bloc dans votre fichier ~/.bashrc_mongodb."
echo "# 2. Enregistrez le fichier ~/.bashrc_mongodb."
echo "# 3. Ajoutez la ligne suivante à votre ~/.bashrc pour charger ce fichier au démarrage du terminal :"
echo "#    source ~/.bashrc_mongodb"
echo "# 4. Exécutez 'source ~/.bashrc' dans votre terminal actuel pour appliquer les changements."
echo ""

# Le reste du script pour les alias Bash reste inchangé
CONFIG_DIR="/etc/mongod"
TOOLS=("mongosh" "mongodump" "mongoexport" "mongofiles" "mongoimport" "mongorestore" "mongostat" "mongotop")

for config_file in "$CONFIG_DIR"/*.conf; do
    if [ -f "$config_file" ]; then
        INSTANCE_NAME=$(basename "$config_file" .conf)
        PORT=$(grep -E '^\s*port:' "$config_file" | awk '{print $2}')

        if [ -z "$PORT" ]; then
            echo "# Avertissement: Impossible de trouver le port dans '$config_file'. Alias non générés pour cette instance."
            continue
        fi

        echo "# Alias pour l'instance '$INSTANCE_NAME' sur le port '$PORT'"
        for tool in "${TOOLS[@]}"; do
            ALIAS_NAME="${tool}_${INSTANCE_NAME}"
            if [ "$tool" == "mongosh" ]; then
                echo "alias ${ALIAS_NAME}='${tool} --port ${PORT}'"
            else
                echo "alias ${ALIAS_NAME}='${tool} --port ${PORT} ${AUTH_STRING}'"
            fi
        done
        echo ""
    fi
done

echo "# Fin des alias MongoDB"
