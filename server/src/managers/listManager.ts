import crypto from "crypto";
import dbContext from "../context/dbContext";
import { badRequest, forbidden, HttpError, notFound } from "../middleware/errors";

// List and item JSON use the same snake_case shape the app stores locally
// (ShoppingListEntity.toJson in the Flutter app), so it can parse either.

type Role = "owner" | "editor";

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_OFFER_JSON = 4000;
const MAX_IMPORT_LISTS = 50;
const MAX_IMPORT_ITEMS = 500;

function idOrNew(value: unknown): string {
  if (value === undefined || value === null) return crypto.randomUUID();
  if (typeof value !== "string" || !UUID_PATTERN.test(value)) throw badRequest("Invalid id");
  return value.toLowerCase();
}

function requiredText(value: unknown, field: string, max: number): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length === 0) throw badRequest(`${field} cannot be empty`);
  if (text.length > max) throw badRequest(`${field} is too long`);
  return text;
}

function optionalText(value: unknown, field: string, max: number): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "string") throw badRequest(`Invalid ${field}`);
  const text = value.trim();
  if (text.length > max) throw badRequest(`${field} is too long`);
  return text.length === 0 ? null : text;
}

function offerJson(value: unknown): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "object" || Array.isArray(value)) throw badRequest("Invalid offer");
  const json = JSON.stringify(value);
  if (json.length > MAX_OFFER_JSON) throw badRequest("Offer is too large");
  return json;
}

function timestamp(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

/** The caller's role on a list, or null when they have no access. */
async function roleOn(listId: string, userId: string): Promise<Role | null> {
  if (!UUID_PATTERN.test(listId)) return null;
  const result = await dbContext.query(
    `SELECT CASE WHEN l.owner_id = $2 THEN 'owner'
                 WHEN m.user_id IS NOT NULL THEN 'editor' END AS role
     FROM lists l
     LEFT JOIN list_members m ON m.list_id = l.id AND m.user_id = $2
     WHERE l.id = $1`,
    [listId, userId]
  );
  return (result.rows[0]?.role as Role | undefined) ?? null;
}

async function requireRole(listId: string, userId: string, owner = false): Promise<Role> {
  const role = await roleOn(listId, userId);
  if (!role) throw notFound("List not found");
  if (owner && role !== "owner") throw forbidden("Only the owner can do this");
  return role;
}

async function touch(listId: string): Promise<void> {
  await dbContext.query("UPDATE lists SET updated_at = now() WHERE id = $1", [listId]);
}

function itemJson(row: any) {
  return {
    id: row.id,
    name: row.name,
    quantity: row.quantity,
    category: row.category,
    is_completed: row.is_completed,
    offer: row.offer,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

/** Lists the user owns or is a member of, with items, owner and members. */
async function loadLists(userId: string, listId?: string) {
  const params: unknown[] = [userId];
  let filter = "";
  if (listId) {
    params.push(listId);
    filter = "AND l.id = $2";
  }
  const lists = await dbContext.query(
    `SELECT l.id, l.name, l.created_at, l.updated_at, l.owner_id,
            o.display_name AS owner_name, o.email AS owner_email,
            CASE WHEN l.owner_id = $1 THEN 'owner' ELSE 'editor' END AS role
     FROM lists l
     JOIN users o ON o.id = l.owner_id
     WHERE (l.owner_id = $1 OR EXISTS (
       SELECT 1 FROM list_members m WHERE m.list_id = l.id AND m.user_id = $1)) ${filter}
     ORDER BY l.updated_at DESC`,
    params
  );
  if (lists.rows.length === 0) return [];

  const ids = lists.rows.map((l: any) => l.id);
  const items = await dbContext.query(
    "SELECT * FROM list_items WHERE list_id = ANY($1) ORDER BY created_at ASC, id ASC",
    [ids]
  );
  const members = await dbContext.query(
    `SELECT m.list_id, u.id, u.display_name, u.email
     FROM list_members m JOIN users u ON u.id = m.user_id
     WHERE m.list_id = ANY($1) ORDER BY m.added_at ASC`,
    [ids]
  );

  return lists.rows.map((l: any) => {
    const listMembers = members.rows
      .filter((m: any) => m.list_id === l.id)
      .map((m: any) => ({ id: m.id, display_name: m.display_name, email: m.email }));
    return {
      id: l.id,
      name: l.name,
      description: null,
      is_shared: listMembers.length > 0,
      created_at: l.created_at,
      updated_at: l.updated_at,
      role: l.role,
      owner: { id: l.owner_id, display_name: l.owner_name, email: l.owner_email },
      members: listMembers,
      items: items.rows.filter((i: any) => i.list_id === l.id).map(itemJson),
    };
  });
}

export const getLists = (userId: string) => loadLists(userId);

export async function getList(listId: string, userId: string) {
  await requireRole(listId, userId);
  return (await loadLists(userId, listId))[0];
}

export async function createList(userId: string, body: any) {
  const id = idOrNew(body?.id);
  const name = requiredText(body?.name, "List name", 255);
  const existing = await dbContext.query("SELECT owner_id FROM lists WHERE id = $1", [id]);
  if (existing.rows[0]) {
    // Retried upload of the same list: idempotent for its owner.
    if (existing.rows[0].owner_id === userId) return getList(id, userId);
    throw new HttpError(409, "A list with this id already exists");
  }
  await dbContext.query("INSERT INTO lists (id, owner_id, name) VALUES ($1, $2, $3)", [id, userId, name]);
  return getList(id, userId);
}

export async function renameList(listId: string, userId: string, body: any) {
  await requireRole(listId, userId);
  const name = requiredText(body?.name, "List name", 255);
  await dbContext.query("UPDATE lists SET name = $2, updated_at = now() WHERE id = $1", [listId, name]);
  return getList(listId, userId);
}

export async function deleteList(listId: string, userId: string): Promise<void> {
  await requireRole(listId, userId, true);
  await dbContext.query("DELETE FROM lists WHERE id = $1", [listId]);
}

export async function addItem(listId: string, userId: string, body: any) {
  await requireRole(listId, userId);
  const id = idOrNew(body?.id);
  const result = await dbContext.query(
    `INSERT INTO list_items (id, list_id, name, quantity, category, is_completed, offer, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, COALESCE($8::timestamptz, now()))
     ON CONFLICT (id) DO NOTHING
     RETURNING *`,
    [
      id,
      listId,
      requiredText(body?.name, "Item name", 255),
      optionalText(body?.quantity, "Quantity", 50),
      optionalText(body?.category, "Category", 255),
      Boolean(body?.is_completed ?? body?.isCompleted ?? false),
      offerJson(body?.offer),
      timestamp(body?.created_at),
    ]
  );
  if (result.rows.length === 0) {
    // Same id again: fine when it is the same list (retried request).
    const existing = await dbContext.query("SELECT * FROM list_items WHERE id = $1 AND list_id = $2", [id, listId]);
    if (!existing.rows[0]) throw new HttpError(409, "An item with this id already exists");
    return itemJson(existing.rows[0]);
  }
  await touch(listId);
  return itemJson(result.rows[0]);
}

export async function updateItem(listId: string, itemId: string, userId: string, body: any) {
  await requireRole(listId, userId);
  const sets: string[] = [];
  const params: unknown[] = [itemId, listId];
  const set = (column: string, value: unknown) => {
    params.push(value);
    sets.push(`${column} = $${params.length}`);
  };
  if (body?.name !== undefined) set("name", requiredText(body.name, "Item name", 255));
  if (body?.quantity !== undefined) set("quantity", optionalText(body.quantity, "Quantity", 50));
  if (body?.category !== undefined) set("category", optionalText(body.category, "Category", 255));
  const completed = body?.is_completed ?? body?.isCompleted;
  if (completed !== undefined) set("is_completed", Boolean(completed));
  if (body?.offer !== undefined) set("offer", offerJson(body.offer));
  if (sets.length === 0) throw badRequest("Nothing to update");

  const result = await dbContext.query(
    `UPDATE list_items SET ${sets.join(", ")}, updated_at = now()
     WHERE id = $1 AND list_id = $2 RETURNING *`,
    params
  );
  if (!result.rows[0]) throw notFound("Item not found");
  await touch(listId);
  return itemJson(result.rows[0]);
}

export async function deleteItem(listId: string, itemId: string, userId: string): Promise<void> {
  await requireRole(listId, userId);
  await dbContext.query("DELETE FROM list_items WHERE id = $1 AND list_id = $2", [itemId, listId]);
  await touch(listId);
}

/** Owner shares the list with another existing account by email. */
export async function addMember(listId: string, userId: string, body: any) {
  await requireRole(listId, userId, true);
  const email = typeof body?.email === "string" ? body.email.trim().toLowerCase() : "";
  if (!email) throw badRequest("Enter an email address");
  const target = await dbContext.query(
    "SELECT id FROM users WHERE LOWER(email) = $1 AND is_active",
    [email]
  );
  if (!target.rows[0]) throw notFound("No Baskit account with this email");
  if (target.rows[0].id === userId) throw badRequest("You already own this list");
  await dbContext.query(
    "INSERT INTO list_members (list_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
    [listId, target.rows[0].id]
  );
  await touch(listId);
  return getList(listId, userId);
}

/** The owner removes a member, or a member leaves ("me"). */
export async function removeMember(listId: string, userId: string, memberId: string): Promise<void> {
  const role = await requireRole(listId, userId);
  const target = memberId === "me" ? userId : memberId;
  if (role !== "owner" && target !== userId) throw forbidden("Only the owner can remove others");
  if (role === "owner" && target === userId) throw badRequest("The owner cannot leave; delete the list instead");
  await dbContext.query("DELETE FROM list_members WHERE list_id = $1 AND user_id = $2", [listId, target]);
  await touch(listId);
}

/**
 * Uploads lists made on a device before signing in. Lists whose id already
 * exists for this user are skipped, so a retried upload does not duplicate.
 */
export async function importLists(userId: string, body: any) {
  const lists = body?.lists;
  if (!Array.isArray(lists)) throw badRequest("lists must be an array");
  if (lists.length > MAX_IMPORT_LISTS) throw badRequest(`At most ${MAX_IMPORT_LISTS} lists`);
  const itemCount = lists.reduce((sum: number, l: any) => sum + (Array.isArray(l?.items) ? l.items.length : 0), 0);
  if (itemCount > MAX_IMPORT_ITEMS) throw badRequest(`At most ${MAX_IMPORT_ITEMS} items`);

  let imported = 0;
  await dbContext.transaction(async (client) => {
    for (const list of lists) {
      const id = idOrNew(list?.id);
      const exists = await client.query("SELECT owner_id FROM lists WHERE id = $1", [id]);
      if (exists.rows[0]) continue;
      await client.query(
        `INSERT INTO lists (id, owner_id, name, created_at, updated_at)
         VALUES ($1, $2, $3, COALESCE($4::timestamptz, now()), COALESCE($5::timestamptz, now()))`,
        [id, userId, requiredText(list?.name, "List name", 255), timestamp(list?.created_at), timestamp(list?.updated_at)]
      );
      for (const item of Array.isArray(list?.items) ? list.items : []) {
        await client.query(
          `INSERT INTO list_items (id, list_id, name, quantity, category, is_completed, offer, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, COALESCE($8::timestamptz, now()))
           ON CONFLICT (id) DO NOTHING`,
          [
            idOrNew(item?.id),
            id,
            requiredText(item?.name, "Item name", 255),
            optionalText(item?.quantity, "Quantity", 50),
            optionalText(item?.category, "Category", 255),
            Boolean(item?.is_completed ?? false),
            offerJson(item?.offer),
            timestamp(item?.created_at),
          ]
        );
      }
      imported++;
    }
  });
  return { imported, lists: await getLists(userId) };
}
