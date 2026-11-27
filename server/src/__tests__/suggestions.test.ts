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

type User = Awaited<ReturnType<typeof signUp>>;

async function add(user: User, listId: string, name: string, id: string = crypto.randomUUID()) {
  const res = await user.call("POST", `/lists/${listId}/items`, { id, name });
  assert.equal(res.status, 201);
  return res.body;
}

async function suggest(user: User, q = "", limit?: number): Promise<string[]> {
  const query = new URLSearchParams({ q, ...(limit ? { limit: String(limit) } : {}) });
  const res = await user.call("GET", `/items/suggestions?${query}`);
  assert.equal(res.status, 200);
  return res.body.map((s: { name: string }) => s.name);
}

test("items the user added before are suggested, most used first", async () => {
  const user = await signUp(server.url, "a@b.nl");
  const list = (await user.call("POST", "/lists", { name: "Weekly" })).body;
  await add(user, list.id, "Halfvolle melk");
  await add(user, list.id, "Melk");
  await add(user, list.id, "melk ");
  await add(user, list.id, "Brood");

  // Starts with the text before contains it; same name in any case is one.
  assert.deepEqual(await suggest(user, "mel"), ["melk", "Halfvolle melk"]);
  assert.deepEqual(await suggest(user, "MELK"), ["melk", "Halfvolle melk"]);
  // Without text: the most used items.
  assert.deepEqual(await suggest(user, "", 2), ["melk", "Halfvolle melk"]);
});

test("the history stays when items are removed and counts a retried add once", async () => {
  const user = await signUp(server.url, "a@b.nl");
  const list = (await user.call("POST", "/lists", { name: "Weekly" })).body;
  const itemId = crypto.randomUUID();
  await add(user, list.id, "Koffie", itemId);
  await add(user, list.id, "Koffie", itemId);
  await add(user, list.id, "Thee");
  await add(user, list.id, "Thee");
  assert.equal((await user.call("DELETE", `/lists/${list.id}/items/${itemId}`)).status, 204);

  const res = await user.call("GET", "/items/suggestions?q=");
  assert.deepEqual(
    res.body.map((s: { name: string; times_added: number }) => [s.name, s.times_added]),
    [["Thee", 2], ["Koffie", 1]]
  );
});

test("the history is per user, also in a shared list", async () => {
  const owner = await signUp(server.url, "owner@b.nl", "Owner");
  const member = await signUp(server.url, "member@b.nl", "Member");
  const list = (await owner.call("POST", "/lists", { name: "Household" })).body;
  await owner.call("POST", `/lists/${list.id}/members`, { email: "member@b.nl" });
  await add(owner, list.id, "Kaas");
  await add(member, list.id, "Kip");

  assert.deepEqual(await suggest(owner), ["Kaas"]);
  assert.deepEqual(await suggest(member), ["Kip"]);
});

test("suggestions need a sign-in and keep the limit in bounds", async () => {
  assert.equal((await client(server.url).call("GET", "/items/suggestions?q=a")).status, 401);
  const user = await signUp(server.url, "a@b.nl");
  const list = (await user.call("POST", "/lists", { name: "Weekly" })).body;
  for (let i = 0; i < 25; i++) await add(user, list.id, `Item ${i}`);

  assert.equal((await suggest(user, "item")).length, 8);
  assert.equal((await suggest(user, "item", 100)).length, 20);
  assert.equal((await user.call("GET", "/items/suggestions?limit=abc")).status, 400);
  assert.equal((await user.call("GET", `/items/suggestions?q=${"x".repeat(101)}`)).status, 400);
});
