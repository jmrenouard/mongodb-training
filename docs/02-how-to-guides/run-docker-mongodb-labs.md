# How to Run Docker MongoDB Labs

Use this procedure to configure, start, verify, and stop the MongoDB Docker Compose stacks.

## Prerequisites

- Confirm Docker Engine and Docker Compose are installed on the host.
- Confirm local host ports `27017` through `27027` and `8081` are free.

NOTE: Review all container names and ports in [Scripts, Compose, and Known Issues Reference](../03-reference/scripts-compose-and-known-issues.md).

## Procedure

### Launch the Standalone Stack

CAUTION: Change the default `admin1` password inside `docker/standalone/compose.yaml` before you expose ports outside localhost.

1. Run configuration validation from the repository root:

```bash
docker compose -f docker/standalone/compose.yaml config -q
```

2. Start the standalone MongoDB and `mongo-express` containers:

```bash
docker compose -f docker/standalone/compose.yaml up -d
```

### Prepare and Launch the Sharded Stack

WARNING: Change all sample secrets inside `docker/sharded/.env_example` and `init-scripts/*.js` before deployment on shared networks.

1. Create a local environment file from `docker/sharded/.env_example`:

```bash
cp docker/sharded/.env_example docker/sharded/.env
```

2. Initialize host data folders and the replica-set keyfile inside `docker/sharded/`:

```bash
(cd docker/sharded && bash init-scripts/init-datadir.sh && set -a && source .env && set +a && bash init-scripts/init-keyfile.sh)
```

3. Validate the Compose file with your environment file:

```bash
docker compose --env-file docker/sharded/.env -f docker/sharded/docker-compose.yml config -q
```

4. Start the 12-container sharded cluster:

```bash
docker compose --env-file docker/sharded/.env -f docker/sharded/docker-compose.yml up -d
```

## Validation

List active containers for your chosen lab:

```bash
docker compose -f docker/standalone/compose.yaml ps
```

If you deployed the sharded stack, check `mongos-router-1` connectivity:

```bash
docker exec mongos-router-1 mongosh --port 27017 --eval "sh.status()"
```

## Rollback

If setup fails or lab work ends, stop and remove the standalone stack cleanly:

```bash
docker compose -f docker/standalone/compose.yaml down
```

If you started the sharded stack, stop and remove all cluster containers:

```bash
docker compose --env-file docker/sharded/.env -f docker/sharded/docker-compose.yml down
```

CAUTION: Delete files under `docker/sharded/data/` only when you want permanent test data loss.

Read architecture trade-offs in [Topology and Backup Architecture](../04-explanation/topology-and-backup-architecture.md).
