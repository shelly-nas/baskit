import { NextFunction, Request, Response } from "express";

/**
 * Small in-memory limiter for the sign-in and register endpoints: at most
 * [max] attempts per client IP in [windowMs]. Enough for a single server
 * instance; it resets on restart.
 */
export function rateLimit(max: number, windowMs: number) {
  const hits = new Map<string, { count: number; resetAt: number }>();

  return (req: Request, res: Response, next: NextFunction): void => {
    const now = Date.now();
    const key = req.ip ?? "unknown";
    const entry = hits.get(key);
    if (!entry || entry.resetAt <= now) {
      hits.set(key, { count: 1, resetAt: now + windowMs });
      if (hits.size > 10000) {
        for (const [k, v] of hits) if (v.resetAt <= now) hits.delete(k);
      }
      next();
      return;
    }
    entry.count++;
    if (entry.count > max) {
      res.setHeader("Retry-After", Math.ceil((entry.resetAt - now) / 1000));
      res.status(429).json({ error: "Too many attempts, try again later" });
      return;
    }
    next();
  };
}
