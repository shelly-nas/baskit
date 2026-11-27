import dbContext from "../context/dbContext";
import { HttpError } from "../middleware/errors";
import { idOrNew, optionalText, requiredId, requiredText } from "./validation";

const COLUMNS = "id, name, quantity, created_at";

/** The user's favorites, by name. */
export async function list(userId: string) {
  const result = await dbContext.query(
    `SELECT ${COLUMNS} FROM favorites WHERE user_id = $1 ORDER BY LOWER(name)`,
    [userId]
  );
  return result.rows;
}

/** Adds a favorite. The same id again returns it (a retried request). */
export async function add(userId: string, body: any) {
  const id = idOrNew(body?.id);
  const name = requiredText(body?.name, "Name", 255);
  const quantity = optionalText(body?.quantity, "Quantity", 50);
  const existing = await dbContext.query(`SELECT ${COLUMNS}, user_id FROM favorites WHERE id = $1`, [id]);
  if (existing.rows[0]) {
    if (existing.rows[0].user_id !== userId) throw new HttpError(409, "A favorite with this id already exists");
    const { user_id: _owner, ...favorite } = existing.rows[0];
    return favorite;
  }
  const sameName = await dbContext.query(
    "SELECT name FROM favorites WHERE user_id = $1 AND LOWER(name) = LOWER($2)",
    [userId, name]
  );
  if (sameName.rows[0]) throw new HttpError(409, `${sameName.rows[0].name} is already a favorite`);
  try {
    const result = await dbContext.query(
      `INSERT INTO favorites (id, user_id, name, quantity) VALUES ($1, $2, $3, $4) RETURNING ${COLUMNS}`,
      [id, userId, name, quantity]
    );
    return result.rows[0];
  } catch (e) {
    // Two requests for the same name at once: the unique index stops one.
    if ((e as { code?: string }).code === "23505") throw new HttpError(409, `${name} is already a favorite`);
    throw e;
  }
}

/** Removes a favorite of the user; one that is not there is already gone. */
export async function remove(userId: string, id: unknown): Promise<void> {
  await dbContext.query("DELETE FROM favorites WHERE id = $1 AND user_id = $2", [requiredId(id), userId]);
}
