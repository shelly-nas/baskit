import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { config } from "../config";
import dbContext from "../context/dbContext";

export interface AuthUser {
  id: string;
  email: string;
  displayName: string;
  role: "user" | "admin";
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export function signToken(userId: string): string {
  return jwt.sign({ sub: userId }, config.jwtSecret, {
    expiresIn: config.tokenTtl as jwt.SignOptions["expiresIn"],
    algorithm: "HS256",
  });
}

/**
 * Requires a valid "Authorization: Bearer <token>" header. The user is read
 * from the database on every request, so a deactivated account or a role
 * change takes effect immediately.
 */
export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    res.status(401).json({ error: "Sign in required" });
    return;
  }

  let userId: string;
  try {
    const payload = jwt.verify(token, config.jwtSecret, { algorithms: ["HS256"] });
    userId = String((payload as jwt.JwtPayload).sub);
  } catch {
    res.status(401).json({ error: "Session expired, sign in again" });
    return;
  }

  try {
    const result = await dbContext.query(
      "SELECT id, email, display_name, role, is_active FROM users WHERE id = $1",
      [userId]
    );
    const row = result.rows[0];
    if (!row || !row.is_active) {
      res.status(401).json({ error: "Account not available" });
      return;
    }
    req.user = { id: row.id, email: row.email, displayName: row.display_name, role: row.role };
    next();
  } catch (error) {
    next(error);
  }
}

export function requireAdmin(req: Request, res: Response, next: NextFunction): void {
  if (req.user?.role !== "admin") {
    res.status(403).json({ error: "Admins only" });
    return;
  }
  next();
}
