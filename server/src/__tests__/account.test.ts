import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { client, dbContext, resetDatabase, signUp, startServer, TestServer } from "./helpers";

// Own file (own process), so the per-IP limit on password attempts starts fresh.
let server: TestServer;

before(async () => {
  server = await startServer();
});
after(async () => {
  await server.close();
  await dbContext.pool.end();
});
beforeEach(resetDatabase);

test("delete the account with its own lists", async () => {
  const owner = await signUp(server.url, "owner@b.nl", "Owner");
  const member = await signUp(server.url, "member@b.nl", "Member");
  const listId = "11111111-1111-4111-8111-111111111111";
  const sharedId = "22222222-2222-4222-8222-222222222222";
  await owner.call("POST", "/lists", { id: listId, name: "Weekend" });
  await member.call("POST", "/lists", { id: sharedId, name: "Household" });
  await member.call("POST", `/lists/${sharedId}/members`, { email: "owner@b.nl" });

  assert.equal((await owner.call("DELETE", "/auth/me", { password: "wrong password" })).status, 400);
  assert.equal((await owner.call("DELETE", "/auth/me", { password: "correct horse" })).status, 204);

  // The token no longer works, signing in fails and the own list is gone.
  assert.equal((await owner.call("GET", "/auth/me")).status, 401);
  const signIn = await client(server.url).call("POST", "/auth/login", { email: "owner@b.nl", password: "correct horse" });
  assert.equal(signIn.status, 401);
  const lists = await dbContext.query("SELECT id FROM lists ORDER BY name");
  assert.deepEqual(lists.rows.map((r: any) => r.id), [sharedId]);
  const members = await dbContext.query("SELECT COUNT(*)::int AS n FROM list_members");
  assert.equal(members.rows[0].n, 0);
});
