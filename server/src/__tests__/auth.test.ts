import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
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

test("register, sign in and read the profile", async () => {
  const anonymous = client(server.url);
  const registered = await anonymous.call("POST", "/auth/register", {
    email: "  Jelle@Example.com ",
    password: "correct horse",
    displayName: "Jelle",
  });
  assert.equal(registered.status, 201);
  assert.equal(registered.body.user.email, "jelle@example.com");
  assert.equal(registered.body.user.role, "user");
  assert.ok(registered.body.token);

  const login = await anonymous.call("POST", "/auth/login", {
    email: "JELLE@example.com",
    password: "correct horse",
  });
  assert.equal(login.status, 200);

  const me = await client(server.url, login.body.token).call("GET", "/auth/me");
  assert.equal(me.status, 200);
  assert.equal(me.body.display_name, "Jelle");
  assert.equal(me.body.password_hash, undefined);
});

test("rejects bad input, duplicates and wrong passwords", async () => {
  const anonymous = client(server.url);
  assert.equal((await anonymous.call("POST", "/auth/register", { email: "x", password: "correct horse", displayName: "A" })).status, 400);
  assert.equal((await anonymous.call("POST", "/auth/register", { email: "a@b.nl", password: "short", displayName: "A" })).status, 400);
  await signUp(server.url, "a@b.nl");
  assert.equal((await anonymous.call("POST", "/auth/register", { email: "A@B.nl", password: "correct horse", displayName: "A" })).status, 409);
  const wrong = await anonymous.call("POST", "/auth/login", { email: "a@b.nl", password: "wrong password" });
  assert.equal(wrong.status, 401);
  assert.equal(wrong.body.error, "Email or password is incorrect");
});

test("requires a valid token", async () => {
  assert.equal((await client(server.url).call("GET", "/lists")).status, 401);
  assert.equal((await client(server.url, "not-a-token").call("GET", "/lists")).status, 401);
});

test("change name and password", async () => {
  const user = await signUp(server.url, "p@b.nl");
  const renamed = await user.call("PATCH", "/auth/me", { displayName: "New name" });
  assert.equal(renamed.body.display_name, "New name");
  const badCurrent = await user.call("PATCH", "/auth/me", { currentPassword: "nope", newPassword: "another secret" });
  assert.equal(badCurrent.status, 400);
  const changed = await user.call("PATCH", "/auth/me", { currentPassword: "correct horse", newPassword: "another secret" });
  assert.equal(changed.status, 200);
  const login = await client(server.url).call("POST", "/auth/login", { email: "p@b.nl", password: "another secret" });
  assert.equal(login.status, 200);
});

test("admin manages users; others are refused", async () => {
  const admin = await signUp(server.url, "admin@b.nl", "Admin");
  await dbContext.query("UPDATE users SET role = 'admin' WHERE id = $1", [admin.userId]);
  const user = await signUp(server.url, "user@b.nl", "User");

  assert.equal((await user.call("GET", "/admin/users")).status, 403);

  const listed = await admin.call("GET", "/admin/users");
  assert.equal(listed.status, 200);
  assert.deepEqual(listed.body.map((u: any) => u.email), ["admin@b.nl", "user@b.nl"]);

  const stats = await admin.call("GET", "/admin/stats");
  assert.equal(stats.body.users, 2);

  assert.equal((await admin.call("PATCH", `/admin/users/${admin.userId}`, { role: "user" })).status, 400);

  const disabled = await admin.call("PATCH", `/admin/users/${user.userId}`, { isActive: false });
  assert.equal(disabled.body.is_active, false);
  // A disabled account is signed out at once and cannot sign in.
  assert.equal((await user.call("GET", "/lists")).status, 401);
  const login = await client(server.url).call("POST", "/auth/login", { email: "user@b.nl", password: "correct horse" });
  assert.equal(login.status, 403);
});
