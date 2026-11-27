import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import crypto from "crypto";
import { client, dbContext, resetDatabase, signUp, startServer, TestServer } from "./helpers";

let server: TestServer;

before(async () => {
  server = await startServer();
});
after(async () => {
  await server.close();
  await dbContext.pool.end();
});
beforeEach(resetDatabase);

test("add, list and remove favorites", async () => {
  const user = await signUp(server.url, "a@b.nl");
  const id = crypto.randomUUID();
  const created = await user.call("POST", "/favorites", { id, name: " Melk ", quantity: "2" });
  assert.equal(created.status, 201);
  assert.deepEqual(
    { id: created.body.id, name: created.body.name, quantity: created.body.quantity },
    { id, name: "Melk", quantity: "2" }
  );
  // Retried create (offline queue): same favorite, no duplicate.
  assert.equal((await user.call("POST", "/favorites", { id, name: "Melk" })).status, 201);
  await user.call("POST", "/favorites", { name: "Brood" });

  const all = await user.call("GET", "/favorites");
  assert.deepEqual(all.body.map((f: { name: string }) => f.name), ["Brood", "Melk"]);

  assert.equal((await user.call("DELETE", `/favorites/${id}`)).status, 204);
  assert.deepEqual((await user.call("GET", "/favorites")).body.map((f: { name: string }) => f.name), ["Brood"]);
  // Deleting again is fine (also from an offline queue).
  assert.equal((await user.call("DELETE", `/favorites/${id}`)).status, 204);
});

test("one favorite per name, in any case", async () => {
  const user = await signUp(server.url, "a@b.nl");
  assert.equal((await user.call("POST", "/favorites", { name: "Melk" })).status, 201);
  const again = await user.call("POST", "/favorites", { name: "melk" });
  assert.equal(again.status, 409);
  assert.equal(again.body.error, "Melk is already a favorite");

  // At the same time: one gets it, the other a clear answer.
  const both = await Promise.all([
    user.call("POST", "/favorites", { name: "Brood" }),
    user.call("POST", "/favorites", { name: "brood" }),
  ]);
  assert.deepEqual(both.map((r) => r.status).sort(), [201, 409]);
});

test("favorites are private and validated", async () => {
  const a = await signUp(server.url, "a@b.nl");
  const b = await signUp(server.url, "b@b.nl");
  const fav = (await a.call("POST", "/favorites", { name: "Kaas" })).body;

  assert.deepEqual((await b.call("GET", "/favorites")).body, []);
  assert.equal((await b.call("DELETE", `/favorites/${fav.id}`)).status, 204);
  assert.equal((await a.call("GET", "/favorites")).body.length, 1);

  assert.equal((await client(server.url).call("GET", "/favorites")).status, 401);
  assert.equal((await a.call("POST", "/favorites", { name: "  " })).status, 400);
  assert.equal((await a.call("POST", "/favorites", { name: "x".repeat(256) })).status, 400);
  assert.equal((await a.call("POST", "/favorites", { id: "nope", name: "x" })).status, 400);
  assert.equal((await a.call("DELETE", "/favorites/nope")).status, 400);
});
