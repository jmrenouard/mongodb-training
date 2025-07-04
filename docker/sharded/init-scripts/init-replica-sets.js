// Configuration des replica sets pour le cluster sharded

// 1. Initialisation du Config Server Replica Set
print("=== Initialisation du Config Server Replica Set ===");
print("=== Initialisation du Shard 1 Replica Set ===");
db = connect("config-server-1:27017/admin");
db.auth("root", "SuperSecurePassword123");
try {
    var configResult = rs.initiate({
        _id: "configReplSet",
        configsvr: true,
        members: [
            { _id: 0, host: "config-server-1:27017" },
            { _id: 1, host: "config-server-2:27017" },
            { _id: 2, host: "config-server-3:27017" }
        ]
    });
    print("Config replica set initialisé:", JSON.stringify(configResult));
} catch (error) {
    print("Erreur lors de l'initialisation du config replica set:", error);
}

// Attendre que le replica set soit prêt
sleep(10000);
rs.status();

// 2. Initialisation du Shard 1 Replica Set
print("=== Initialisation du Shard 1 Replica Set ===");
db = connect("shard1-replica-1:27017/admin");
db.auth("root", "SuperSecurePassword123");

try {
    var shard1Result = rs.initiate({
        _id: "shard1ReplSet",
        members: [
            { _id: 0, host: "shard1-replica-1:27017" },
            { _id: 1, host: "shard1-replica-2:27017" },
            { _id: 2, host: "shard1-replica-3:27017" }
        ]
    });
    print("Shard 1 replica set initialisé:", JSON.stringify(shard1Result));
} catch (error) {
    print("Erreur lors de l'initialisation du shard 1:", error);
}

// Attendre la stabilisation des replica sets
sleep(10000);
rs.status();

// 3. Initialisation du Shard 2 Replica Set
print("=== Initialisation du Shard 2 Replica Set ===");
db = connect("shard2-replica-1:27017/admin");
db.auth("root", "SuperSecurePassword123");

try {
    var shard2Result = rs.initiate({
        _id: "shard2ReplSet",
        members: [
            { _id: 0, host: "shard2-replica-1:27017" },
            { _id: 1, host: "shard2-replica-2:27017" },
            { _id: 2, host: "shard2-replica-3:27017" }
        ]
    });
    print("Shard 2 replica set initialisé:", JSON.stringify(shard2Result));
} catch (error) {
    print("Erreur lors de l'initialisation du shard 2:", error);
}

// Attendre la stabilisation des replica sets
sleep(10000);
rs.status();

// 4. Ajout des shards au cluster
print("=== Ajout des shards au cluster ===");
db = connect("mongos-router-1:27017/admin");
db.auth("root", "SuperSecurePassword123");

try {
    var addShard1 = sh.addShard("shard1ReplSet/shard1-replica-1:27017,shard1-replica-2:27017,shard1-replica-3:27017");
    print("Shard 1 ajouté:", JSON.stringify(addShard1));
    
    var addShard2 = sh.addShard("shard2ReplSet/shard2-replica-1:27017,shard2-replica-2:27017,shard2-replica-3:27017");
    print("Shard 2 ajouté:", JSON.stringify(addShard2));
} catch (error) {
    print("Erreur lors de l'ajout des shards:", error);
}

print("=== Configuration des replica sets terminée ===");
