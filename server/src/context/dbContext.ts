import { Pool, PoolClient } from "pg";
import "../config";

class DbContext {
  public pool: Pool;

  constructor() {
    this.pool = new Pool({
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: process.env.DB_PASSWORD,
      port: parseInt(process.env.DB_PORT || "5432", 10),
    });
  }

  public query<T extends Record<string, any> = any>(text: string, params?: unknown[]) {
    return this.pool.query<T>(text, params as any[]);
  }

  public connect(): Promise<PoolClient> {
    return this.pool.connect();
  }

  /** Runs [callback] in a transaction on one connection. */
  public async transaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query("BEGIN");
      const result = await callback(client);
      await client.query("COMMIT");
      return result;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }
}

export default new DbContext();
