import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { client, dbContext, resetDatabase, signUp, startServer, TestServer } from "./helpers";

// Own file (own process), so the per-IP limit of 20 password attempts per 15
// minutes starts fresh; these tests use 19 of them.
let server: TestServer;

before(async () => {
  server = await startServer();
});
after(async () => {
  await server.close();
  await dbContext.pool.end();
});
beforeEach(resetDatabase);

const login = (password: string) =>
  client(server.url).call("POST", "/auth/login", { email: "lock@b.nl", password });

test("locks an account after 10 failed sign-ins", async () => {
  await signUp(server.url, "lock@b.nl");

  for (let i = 0; i < 10; i++) {
    assert.equal((await login("wrong password")).status, 401);
  }
  // Locked: even the right password is refused.
  const locked = await login("correct horse");
  assert.equal(locked.status, 429);
  assert.equal(locked.body.error, "Too many failed attempts, try again in 15 minutes");

  // Once the lock has expired the right password works again.
  await dbContext.query("UPDATE users SET locked_until = now() - interval '1 second'");
  assert.equal((await login("correct horse")).status, 200);
});

test("a successful sign-in resets the failed attempts", async () => {
  await signUp(server.url, "lock@b.nl");
  for (let i = 0; i < 4; i++) await login("wrong password");
  assert.equal((await login("correct horse")).status, 200);
  const row = await dbContext.query("SELECT failed_login_count, locked_until FROM users");
  assert.equal(row.rows[0].failed_login_count, 0);
  assert.equal(row.rows[0].locked_until, null);
});
