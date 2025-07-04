#!/bin/bash

# Nom du script : create_mongodb_admin.sh
# Description : Crée un utilisateur admin avec le rôle root et le mot de passe 'admin'
#               sur une instance MongoDB spécifiée par son port.
# Utilisation : sudo bash /var/tmp/create_mongodb_admin.sh <PORT_MONGODB>
# Exemple : sudo bash /var/tmp/create_mongodb_admin.sh 27017

# --- Vérification de l'argument ---
if [ -z "$1" ]; then
  echo "Usage: sudo bash $0 <PORT_MONGODB>"
  echo "Exemple: sudo bash $0 27017"
  exit 1
fi

MONGO_PORT="$1"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin" # ⚠️ Avertissement : Mot de passe très faible, à ne pas utiliser en production.

echo "--- Création de l'utilisateur admin MongoDB ---"
echo "Instance MongoDB sur le port : ${MONGO_PORT}"
echo "Nom d'utilisateur : ${ADMIN_USERNAME}"
echo "Mot de passe : ${ADMIN_PASSWORD}"

# Vérifie si mongosh est installé
if ! command -v mongosh &> /dev/null
then
    echo "Erreur : 'mongosh' n'est pas trouvé. Veuillez l'installer."
    exit 1
fi

# Commande mongosh pour créer l'utilisateur
# Nous nous connectons à la base de données 'admin' pour créer un utilisateur avec des rôles globaux.
# Le --eval permet d'exécuter du JavaScript directement.
mongosh --port "${MONGO_PORT}" --authenticationDatabase "admin" <<EOF
use admin
db.createUser(
  {
    user: "${ADMIN_USERNAME}",
    pwd: "${ADMIN_PASSWORD}",
    roles: [ { role: "root", db: "admin" } ]
  }
)
db.grantRolesToUser( "admin", [ "userAdminAnyDatabase","readWriteAnyDatabase" ])
EOF

# Vérifie le code de sortie de mongosh
if [ $? -eq 0 ]; then
    echo ""
    echo "Utilisateur '${ADMIN_USERNAME}' créé avec succès sur l'instance MongoDB au port ${MONGO_PORT}."
    echo "N'oubliez pas d'activer l'authentification dans votre fichier de configuration MongoDB (security.authorization: enabled) et de redémarrer l'instance pour que l'authentification prenne effet."
    echo "Une fois l'authentification activée, vous pourrez vous connecter avec :"
    echo "mongosh --port ${MONGO_PORT} -u ${ADMIN_USERNAME} -p ${ADMIN_PASSWORD} --authenticationDatabase admin"
else
    echo ""
    echo "Erreur lors de la création de l'utilisateur. Veuillez vérifier les logs de MongoDB et les permissions."
    echo "Assurez-vous que l'instance MongoDB est démarrée et accessible, et que l'authentification est désactivée ou que vous avez les privilèges nécessaires."
fi

echo "--- Fin du script de création d'utilisateur ---"
