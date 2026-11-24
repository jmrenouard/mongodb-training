# Exécuter les Laboratoires Docker MongoDB

Utilisez cette procédure pour configurer, démarrer, vérifier et arrêter les piles Docker MongoDB.

## Prérequis

- Vérifiez que Docker Engine et Docker Compose fonctionnent sur le poste.
- Vérifiez que les ports locaux `27017` à `27027` et `8081` restent libres.

NOTE: Consultez les ports et variables dans [Référence des scripts et anomalies](../03-reference/scripts-compose-et-anomalies.md).

## Procédure

### Démarrer la Pile Autonome

ATTENTION: Remplacez le mot de passe `admin1` dans `docker/standalone/compose.yaml` avant toute exposition réseau. Ce mot de passe public expose les bases de test.

1. Validez la configuration depuis la racine du dépôt :

```bash
docker compose -f docker/standalone/compose.yaml config -q
```

2. Démarrez les conteneurs `mongo` et `mongo-express` :

```bash
docker compose -f docker/standalone/compose.yaml up -d
```

### Préparer et Démarrer le Cluster Shardé

ATTENTION: Modifiez tous les secrets dans `docker/sharded/.env` et `init-scripts/*.js` avant un usage partagé. Les secrets par défaut sont publics dans Git.

1. Copiez le fichier modèle `docker/sharded/.env_example` vers `docker/sharded/.env` :

```bash
cp docker/sharded/.env_example docker/sharded/.env
```

2. Préparez les dossiers de données et le fichier `mongodb-keyfile` :

```bash
(cd docker/sharded && bash init-scripts/init-datadir.sh && set -a && source .env && set +a && sudo env "MONGO_REPLICA_SET_KEY=$MONGO_REPLICA_SET_KEY" bash init-scripts/init-keyfile.sh)
```

3. Validez la définition Compose avec votre fichier d'environnement :

```bash
docker compose --env-file docker/sharded/.env -f docker/sharded/docker-compose.yml config -q
```

4. Démarrez les 12 conteneurs du cluster shardé :

```bash
docker compose --env-file docker/sharded/.env -f docker/sharded/docker-compose.yml up -d
```

## Vérification

Affichez la liste des conteneurs actifs de la pile autonome :

```bash
docker compose -f docker/standalone/compose.yaml ps
```

Si le cluster shardé tourne, vérifiez l'état authentifié de `mongos-router-1` :

```bash
(set -a && source docker/sharded/.env && docker exec mongos-router-1 mongosh --port 27017 -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval "sh.status()")
```

## Retour Arrière

Si un échec survient, arrêtez les conteneurs de la pile autonome :

```bash
docker compose -f docker/standalone/compose.yaml down
```

Si vous utilisez le cluster shardé, arrêtez les 12 conteneurs :

```bash
docker compose --env-file docker/sharded/.env -f docker/sharded/docker-compose.yml down
```

ATTENTION: Supprimez `docker/sharded/data/` uniquement après sauvegarde complète. La suppression de ce dossier détruit les données de test de manière définitive.

Consultez les choix techniques dans [Architecture des topologies et sauvegardes](../04-explications/architecture-topologies-et-sauvegardes.md).
