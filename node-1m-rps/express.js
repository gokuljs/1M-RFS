import express from "express";

const app = express();

process.title = "node-express";

app.get("/simple", (req, res) => {
  res.json({ message: "hi" });
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`Express server running at http://localhost:${PORT}`);
});
