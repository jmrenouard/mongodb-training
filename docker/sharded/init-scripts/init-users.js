// Création des utilisateurs administrateurs

print("=== Création des utilisateurs administrateurs ===");

// Connexion au mongos en tant que root
db = connect("mongos-router-1:27017/admin");
db.auth("root", "SuperSecurePassword123");

// 1. Création de l'utilisateur admin avec privilèges d'administration des utilisateurs
try {
    var adminUser = db.createUser({
        user: "admin",
        pwd: "AdminPassword123",
        roles: [
            { role: "userAdminAnyDatabase", db: "admin" },
            { role: "dbAdminAnyDatabase", db: "admin" },
            { role: "readWriteAnyDatabase", db: "admin" }
        ]
    });
    print("Utilisateur 'admin' créé avec succès");
} catch (error) {
    print("Erreur lors de la création de l'utilisateur admin:", error);
}

// 2. Création de l'utilisateur superadmin avec tous les privilèges
try {
    var superAdminUser = db.createUser({
        user: "superadmin",
        pwd: "SuperAdminPassword123",
        roles: [
            { role: "root", db: "admin" },
            { role: "clusterAdmin", db: "admin" },
            { role: "userAdminAnyDatabase", db: "admin" },
            { role: "dbAdminAnyDatabase", db: "admin" },
            { role: "readWriteAnyDatabase", db: "admin" }
        ]
    });
    print("Utilisateur 'superadmin' créé avec succès");
} catch (error) {
    print("Erreur lors de la création de l'utilisateur superadmin:", error);
}

// 3. Affichage de la liste des utilisateurs créés
print("=== Liste des utilisateurs dans la base admin ===");
try {
    var users = db.getUsers();
    users.forEach(function(user) {
        print("Utilisateur:", user.user, "- Rôles:", JSON.stringify(user.roles));
    });
} catch (error) {
    print("Erreur lors de la récupération des utilisateurs:", error);
}

// 4. Vérification du statut du cluster sharded
print("=== Statut du cluster sharded ===");
try {
    var status = sh.status();
    print("Cluster configuré avec succès");
} catch (error) {
    print("Erreur lors de la vérification du statut:", error);
}

print("=== Création des utilisateurs terminée ===");
