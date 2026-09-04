const keys = {
  dbUser: process.env.PGUSER ?? "postgres",
  dbHost: process.env.PGHOST ?? "127.0.0.1",
  dbDatabase: process.env.PGDATABASE ?? "rfs",
  dbPassword: process.env.PGPASSWORD ?? "",
  dbPort: Number(process.env.PGPORT ?? 5432),
};

export default keys;
