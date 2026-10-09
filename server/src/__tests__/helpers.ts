import fs from "fs/promises";
import path from "path";
import { AddressInfo } from "net";
import { Server } from "http";
import dbContext from "../context/dbContext";
import { runMigrations } from "../context/migrations";
import { createApp } from "../app";

const INIT_SQL = path.join(__dirname, "..", "..", "..", "database", "init.sql");

/**
 * Brings the test database to the shipped schema (database/init.sql plus
 * migrations) and empties it. Uses the same files a real install does.
 */
export async function resetDatabase(): Promise<void> {
  const present = await dbContext.query(
    "SELECT to_regclass('public.users') IS NOT NULL AS present"
  );
  if (!present.rows[0].present) {
    await dbContext.query(await fs.readFile(INIT_SQL, "utf8"));
  }
  await runMigrations();
  await dbContext.query("TRUNCATE users, lists, list_items, list_members CASCADE");
}

export interface TestServer {
  url: string;
  close: () => Promise<void>;
}

export async function startServer(): Promise<TestServer> {
  const server: Server = createApp().listen(0);
  await new Promise<void>((resolve) => server.once("listening", () => resolve()));
  const { port } = server.address() as AddressInfo;
  return {
    url: `http://127.0.0.1:${port}/api`,
    close: () => new Promise((resolve) => server.close(() => resolve())),
  };
}

export interface Client {
  token?: string;
  call: (method: string, path: string, body?: unknown) => Promise<{ status: number; body: any }>;
}

export function client(baseUrl: string, token?: string): Client {
  const c: Client = {
    token,
    async call(method, path, body) {
      const response = await fetch(baseUrl + path, {
        method,
        headers: {
          "Content-Type": "application/json",
          ...(c.token ? { Authorization: `Bearer ${c.token}` } : {}),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      const text = await response.text();
      return { status: response.status, body: text ? JSON.parse(text) : null };
    },
  };
  return c;
}

/** Registers an account and returns a client signed in as it. */
export async function signUp(baseUrl: string, email: string, name = "Test"): Promise<Client & { userId: string }> {
  const anonymous = client(baseUrl);
  const result = await anonymous.call("POST", "/auth/register", {
    email,
    password: "correct horse",
    displayName: name,
  });
  if (result.status !== 201) throw new Error(`register failed: ${JSON.stringify(result.body)}`);
  return Object.assign(client(baseUrl, result.body.token), { userId: result.body.user.id });
}

export { dbContext };
