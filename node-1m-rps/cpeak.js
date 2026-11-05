import cpeak from "cpeak";

const app = cpeak();

process.title = "node-cpeak";

app.route("get", "/simple", (req, res) => {
  res.json({ message: "hi" });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Cpeak server running at http://localhost:${PORT}`);
});
