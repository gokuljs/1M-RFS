import assert from "node:assert/strict";
import { once } from "node:events";
import http from "node:http";
import test from "node:test";

test("Express serves /simple and no longer exposes workload routes", async (t) => {
  let server;
  const listen = http.Server.prototype.listen;

  // Use an available local port without interfering with a running server.
  const listenMock = t.mock.method(
    http.Server.prototype,
    "listen",
    function (_port, callback) {
      server = this;
      return listen.call(this, { port: 0, host: "127.0.0.1" }, callback);
    },
  );

  await import("../express.js");
  listenMock.mock.restore();
  t.after(() => new Promise((resolve) => server.close(resolve)));

  if (!server.listening) await once(server, "listening");
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const response = await fetch(`${baseUrl}/simple`);

  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type"), /application\/json/);
  assert.deepEqual(await response.json(), { message: "hi" });

  const removedRoutes = [
    ["PATCH", "/update-something/123/john_doe"],
    ["POST", "/code"],
    ["GET", "/code-v1"],
    ["GET", "/code-v2"],
    ["GET", "/code-v3"],
    ["GET", "/code-v4"],
    ["POST", "/code-fast"],
    ["GET", "/code-fast"],
  ];

  for (const [method, path] of removedRoutes) {
    const result = await fetch(`${baseUrl}${path}`, { method });
    assert.equal(result.status, 404, `${method} ${path}`);
    await result.text();
  }
});
