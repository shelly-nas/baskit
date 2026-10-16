import bcrypt from "bcryptjs";
import { config } from "../config";
import dbContext from "../context/dbContext";
import { badRequest, HttpError, notFound } from "../middleware/errors";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASSWORD_LENGTH = 8;
const BCRYPT_ROUNDS = 10;

export interface UserJson {
  id: string;
  email: string;
  display_name: string;
  role: "user" | "admin";
  is_active: boolean;
  created_at: string;
  last_login_at: string | null;
}

function toJson(row: any): UserJson {
  return {
    id: row.id,
    email: row.email,
    display_name: row.display_name,
    role: row.role,
    is_active: row.is_active,
    created_at: row.created_at,
    last_login_at: row.last_login_at,
  };
}

const USER_COLUMNS = "id, email, display_name, role, is_active, created_at, last_login_at";

function normalizeEmail(email: unknown): string {
  const value = typeof email === "string" ? email.trim().toLowerCase() : "";
  if (!EMAIL_PATTERN.test(value) || value.length > 255) {
    throw badRequest("Enter a valid email address");
  }
  return value;
}

function validatePassword(password: unknown): string {
  if (typeof password !== "string" || password.length < MIN_PASSWORD_LENGTH) {
    throw badRequest(`Password must be at least ${MIN_PASSWORD_LENGTH} characters`);
  }
  if (password.length > 200) throw badRequest("Password is too long");
  return password;
}

function validateName(name: unknown): string {
  const value = typeof name === "string" ? name.trim() : "";
  if (value.length === 0) throw badRequest("Enter your name");
  if (value.length > 100) throw badRequest("Name is too long");
  return value;
}

const roleFor = (email: string): "user" | "admin" =>
  config.adminEmails.includes(email) ? "admin" : "user";

export async function register(body: any): Promise<UserJson> {
  const email = normalizeEmail(body?.email);
  const password = validatePassword(body?.password);
  const displayName = validateName(body?.displayName);
  const hash = await bcrypt.hash(password, BCRYPT_ROUNDS);

  try {
    const result = await dbContext.query(
      `INSERT INTO users (email, display_name, password_hash, role, last_login_at)
       VALUES ($1, $2, $3, $4, now())
       RETURNING ${USER_COLUMNS}`,
      [email, displayName, hash, roleFor(email)]
    );
    return toJson(result.rows[0]);
  } catch (error: any) {
    if (error?.code === "23505") throw new HttpError(409, "An account with this email already exists");
    throw error;
  }
}

export async function login(body: any): Promise<UserJson> {
  const email = typeof body?.email === "string" ? body.email.trim().toLowerCase() : "";
  const password = typeof body?.password === "string" ? body.password : "";
  const result = await dbContext.query(
    `SELECT ${USER_COLUMNS}, password_hash FROM users WHERE LOWER(email) = $1`,
    [email]
  );
  const row = result.rows[0];
  // Same message whether the email or the password is wrong.
  const valid = row ? await bcrypt.compare(password, row.password_hash) : false;
  if (!row || !valid) throw new HttpError(401, "Email or password is incorrect");
  if (!row.is_active) throw new HttpError(403, "This account has been disabled");

  const updated = await dbContext.query(
    `UPDATE users SET last_login_at = now(),
       role = CASE WHEN $2 THEN 'admin' ELSE role END
     WHERE id = $1 RETURNING ${USER_COLUMNS}`,
    [row.id, config.adminEmails.includes(email)]
  );
  return toJson(updated.rows[0]);
}

export async function getUser(id: string): Promise<UserJson> {
  const result = await dbContext.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = $1`, [id]);
  if (!result.rows[0]) throw notFound("User not found");
  return toJson(result.rows[0]);
}

/** Changes the signed-in user's name and/or password. */
export async function updateMe(id: string, body: any): Promise<UserJson> {
  if (body?.displayName !== undefined) {
    await dbContext.query("UPDATE users SET display_name = $2 WHERE id = $1", [
      id,
      validateName(body.displayName),
    ]);
  }
  if (body?.newPassword !== undefined) {
    const current = await dbContext.query("SELECT password_hash FROM users WHERE id = $1", [id]);
    const ok = await bcrypt.compare(String(body?.currentPassword ?? ""), current.rows[0].password_hash);
    if (!ok) throw badRequest("Current password is incorrect");
    const hash = await bcrypt.hash(validatePassword(body.newPassword), BCRYPT_ROUNDS);
    await dbContext.query("UPDATE users SET password_hash = $2 WHERE id = $1", [id, hash]);
  }
  return getUser(id);
}

export async function listUsers(): Promise<(UserJson & { list_count: number })[]> {
  const result = await dbContext.query(
    `SELECT ${USER_COLUMNS.split(", ").map((c) => `u.${c}`).join(", ")},
            (SELECT COUNT(*) FROM lists l WHERE l.owner_id = u.id)::int AS list_count
     FROM users u ORDER BY u.created_at ASC`
  );
  return result.rows.map((row: any) => ({ ...toJson(row), list_count: row.list_count }));
}

/** Admin: change a user's role or (de)activate the account. */
export async function adminUpdateUser(adminId: string, id: string, body: any): Promise<UserJson> {
  if (id === adminId && (body?.role === "user" || body?.isActive === false)) {
    throw badRequest("You cannot remove your own admin access");
  }
  if (body?.role !== undefined) {
    if (body.role !== "user" && body.role !== "admin") throw badRequest("Unknown role");
    await dbContext.query("UPDATE users SET role = $2 WHERE id = $1", [id, body.role]);
  }
  if (body?.isActive !== undefined) {
    await dbContext.query("UPDATE users SET is_active = $2 WHERE id = $1", [id, Boolean(body.isActive)]);
  }
  return getUser(id);
}

export async function stats(): Promise<Record<string, number>> {
  const result = await dbContext.query(
    `SELECT
       (SELECT COUNT(*) FROM users)::int AS users,
       (SELECT COUNT(*) FROM users WHERE is_active)::int AS active_users,
       (SELECT COUNT(*) FROM users WHERE last_login_at > now() - interval '30 days')::int AS users_last_30_days,
       (SELECT COUNT(*) FROM lists)::int AS lists,
       (SELECT COUNT(DISTINCT list_id) FROM list_members)::int AS shared_lists,
       (SELECT COUNT(*) FROM list_items)::int AS items`
  );
  return result.rows[0];
}
