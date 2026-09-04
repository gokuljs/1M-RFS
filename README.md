# 1M-RFS

An experimental repository for designing and testing backend systems toward handling up to one million requests.

Initial focus:

- C++
- Node.js
- Redis

Requirements, implementations, benchmarks, and results will be added incrementally. A technical blog post will document the findings. No performance claims are made before testing.

## Local Node/Redis setup

The current Node experiment lives in [`node-1m-rps`](node-1m-rps). Its runtime
assumptions are:

- Node.js 20 or newer
- Redis on `127.0.0.1:6379`
- PostgreSQL on `127.0.0.1:5432` for the database-backed routes and seed/migrate scripts

Install the pinned Node dependencies:

```sh
cd node-1m-rps
npm ci
```

Create the ignored local PostgreSQL configuration from the checked-in
template:

```sh
cp database/keys.example.js database/keys.js
```

Override `PGUSER`, `PGHOST`, `PGDATABASE`, `PGPASSWORD`, or `PGPORT` in the
shell when the local PostgreSQL installation uses different values. The
default database name is `rfs`.

For a quick Redis-only run, start one local Redis server and leave
`REDIS_CLUSTER` unset or set it to `false`. The Redis-backed application routes
will then use the default `127.0.0.1:6379` connection. The existing
`redis.sh -setup` command is reserved for the separate cluster experiment; it
starts 30 local Redis instances on ports 7000–7029.

Initialize PostgreSQL, if needed, and seed data with:

```sh
PG_CONNECT=true npm run seed
```

For a server run that does not require PostgreSQL, use `PG_CONNECT=false`.
The current HTTP entry points are:

```sh
PG_CONNECT=false node express.js  # port 3001
PG_CONNECT=false node fastify.js  # port 3002
PG_CONNECT=false node cpeak.js    # port 3000
```

Run the existing unit tests with:

```sh
npm test
```

This is local execution guidance only; benchmark workload, machine sizing,
cluster topology, and capacity results remain intentionally unspecified until
they are measured and recorded.
