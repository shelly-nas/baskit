import { PoolClient } from "pg";
import dbContext from "../context/dbContext";
import { HttpError } from "../middleware/errors";

const DEFAULT_LIMIT = 8;
const MAX_LIMIT = 20;
const MAX_QUERY = 100;

/** Counts an item the user added, for suggestions; in the caller's transaction. */
export async function recordAdded(client: PoolClient, userId: string, name: string): Promise<void> {
  await client.query(
    `INSERT INTO item_history (user_id, name_key, name) VALUES ($1, LOWER($2), $2)
     ON CONFLICT (user_id, name_key) DO UPDATE
       SET times_added = item_history.times_added + 1, name = EXCLUDED.name, last_added_at = now()`,
    [userId, name]
  );
}

/**
 * Items the user added before that contain [q]: names that start with it
 * first, then the most added, then the most recent. Without [q] the most
 * added items.
 */
export async function suggestions(userId: string, q: unknown, limit: unknown) {
  const text = typeof q === "string" ? q.trim().toLowerCase() : "";
  if (text.length > MAX_QUERY) throw new HttpError(400, "Search text is too long");
  const max = parseLimit(limit);
  const pattern = text.replace(/[\\%_]/g, "\\$&");
  const result = await dbContext.query(
    `SELECT name, times_added FROM item_history
     WHERE user_id = $1 AND name_key LIKE '%' || $2 || '%' ESCAPE '\\'
     ORDER BY (name_key LIKE $2 || '%' ESCAPE '\\') DESC, times_added DESC, last_added_at DESC
     LIMIT $3`,
    [userId, pattern, max]
  );
  return result.rows;
}

function parseLimit(value: unknown): number {
  if (value === undefined || value === "") return DEFAULT_LIMIT;
  if (typeof value !== "string" || !/^\d+$/.test(value)) throw new HttpError(400, "Invalid limit");
  return Math.min(Math.max(Number(value), 1), MAX_LIMIT);
}
