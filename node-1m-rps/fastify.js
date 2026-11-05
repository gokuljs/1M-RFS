import Fastify from "fastify";

const app = Fastify();

process.title = "node-fastify";

app.get("/simple", (req, res) => {
  res.send({ message: "hi" });
});

const PORT = 3002;
app.listen({ port: PORT, host: "0.0.0.0" }, () => {
  console.log(`Fastify server running at http://localhost:${PORT}`);
});
