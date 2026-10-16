import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import crypto from "crypto";
import { dbContext, resetDatabase, signUp, startServer, TestServer } from "./helpers";

let server: TestServer;

before(async () => {
  server = await startServer();
});
after(async () => {
  await server.close();
  await dbContext.pool.end();
});
beforeEach(resetDatabase);

const offer = {
  product_id: 7,
  supermarket_key: "dirk",
  supermarket_name: "Dirk",
  price: 0.79,
  expire_date: "2030-01-01T00:00:00.000Z",
};

test("create a list with client ids and manage items", async () => {
  const user = await signUp(server.url, "a@b.nl");
  const listId = crypto.randomUUID();
  const created = await user.call("POST", "/lists", { id: listId, name: "Weekly" });
  assert.equal(created.status, 201);
  assert.equal(created.body.id, listId);
  assert.equal(created.body.role, "owner");

  // Retried create is idempotent.
  assert.equal((await user.call("POST", "/lists", { id: listId, name: "Weekly" })).status, 201);

  const itemId = crypto.randomUUID();
  const item = await user.call("POST", `/lists/${listId}/items`, { id: itemId, name: "Melk", quantity: "2", offer });
  assert.equal(item.status, 201);
  assert.deepEqual(item.body.offer, offer);

  const toggled = await user.call("PATCH", `/lists/${listId}/items/${itemId}`, { is_completed: true });
  assert.equal(toggled.body.is_completed, true);

  const lists = await user.call("GET", "/lists");
  assert.equal(lists.body.length, 1);
  assert.equal(lists.body[0].items[0].name, "Melk");

  assert.equal((await user.call("DELETE", `/lists/${listId}/items/${itemId}`)).status, 204);
  assert.equal((await user.call("GET", `/lists/${listId}`)).body.items.length, 0);
  assert.equal((await user.call("POST", "/lists", { name: "  " })).status, 400);
  assert.equal((await user.call("POST", `/lists/${listId}/items`, { id: "not-a-uuid", name: "x" })).status, 400);
});

test("lists are private unless shared", async () => {
  const owner = await signUp(server.url, "owner@b.nl", "Owner");
  const other = await signUp(server.url, "other@b.nl", "Other");
  const list = (await owner.call("POST", "/lists", { name: "Private" })).body;

  assert.equal((await other.call("GET", `/lists/${list.id}`)).status, 404);
  assert.equal((await other.call("POST", `/lists/${list.id}/items`, { name: "x" })).status, 404);
  assert.equal((await other.call("DELETE", `/lists/${list.id}`)).status, 404);
  assert.deepEqual((await other.call("GET", "/lists")).body, []);
});

test("share a list: members edit, only the owner deletes and shares", async () => {
  const owner = await signUp(server.url, "owner@b.nl", "Owner");
  const member = await signUp(server.url, "member@b.nl", "Member");
  const third = await signUp(server.url, "third@b.nl", "Third");
  const list = (await owner.call("POST", "/lists", { name: "Household" })).body;

  assert.equal((await owner.call("POST", `/lists/${list.id}/members`, { email: "nobody@b.nl" })).status, 404);
  const shared = await owner.call("POST", `/lists/${list.id}/members`, { email: "MEMBER@b.nl" });
  assert.equal(shared.status, 200);
  assert.equal(shared.body.is_shared, true);
  assert.deepEqual(shared.body.members.map((m: any) => m.display_name), ["Member"]);

  const seen = await member.call("GET", "/lists");
  assert.equal(seen.body[0].role, "editor");
  assert.equal(seen.body[0].owner.display_name, "Owner");

  assert.equal((await member.call("POST", `/lists/${list.id}/items`, { name: "Brood" })).status, 201);
  assert.equal((await owner.call("GET", `/lists/${list.id}`)).body.items[0].name, "Brood");

  assert.equal((await member.call("DELETE", `/lists/${list.id}`)).status, 403);
  assert.equal((await member.call("POST", `/lists/${list.id}/members`, { email: "third@b.nl" })).status, 403);
  assert.equal((await member.call("DELETE", `/lists/${list.id}/members/${third.userId}`)).status, 403);

  // Member leaves.
  assert.equal((await member.call("DELETE", `/lists/${list.id}/members/me`)).status, 204);
  assert.equal((await member.call("GET", `/lists/${list.id}`)).status, 404);
  assert.equal((await owner.call("DELETE", `/lists/${list.id}/members/me`)).status, 400);
});

test("import lists from a device once", async () => {
  const user = await signUp(server.url, "a@b.nl");
  const local = {
    lists: [
      {
        id: crypto.randomUUID(),
        name: "Groceries",
        created_at: "2026-01-01T10:00:00.000Z",
        items: [
          { id: crypto.randomUUID(), name: "Melk", is_completed: true, offer },
          { id: crypto.randomUUID(), name: "Brood", quantity: "1" },
        ],
      },
    ],
  };
  const first = await user.call("POST", "/lists/import", local);
  assert.equal(first.status, 200);
  assert.equal(first.body.imported, 1);
  assert.equal(first.body.lists[0].items.length, 2);

  const again = await user.call("POST", "/lists/import", local);
  assert.equal(again.body.imported, 0);
  assert.equal(again.body.lists.length, 1);
});
