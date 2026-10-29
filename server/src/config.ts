import crypto from "crypto";
import dotenv from "dotenv";

dotenv.config();

const isProduction = process.env.NODE_ENV === "production";

function jwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (secret && secret.length >= 32) return secret;
  if (isProduction) {
    throw new Error("JWT_SECRET must be set (at least 32 characters) in production");
  }
  // Development: tokens stop working on restart, which is fine locally.
  console.warn("JWT_SECRET not set; using a random secret for this process");
  return crypto.randomBytes(48).toString("hex");
}

/** A positive whole number from an env variable; a wrong value stops the server instead of being ignored. */
export function positiveInt(name: string, value: string | undefined, fallback: number): number {
  if (value === undefined || value === "") return fallback;
  if (!/^[1-9]\d*$/.test(value)) {
    throw new Error(`${name} must be a positive whole number (got "${value}")`);
  }
  return Number(value);
}

export const config = {
  port: parseInt(process.env.SERVER_PORT || "3000", 10),
  isProduction,
  jwtSecret: jwtSecret(),
  /** How long a sign-in lasts. Long on purpose: users stay signed in on a device. */
  tokenTtl: process.env.TOKEN_TTL || "365d",
  /** Sign-in and register attempts per client IP per 15 minutes. Acc raises it for the E2E run. */
  authRateLimit: positiveInt("AUTH_RATE_LIMIT", process.env.AUTH_RATE_LIMIT, 20),
  /** Accounts with these emails get the admin role when they register or sign in. */
  adminEmails: (process.env.ADMIN_EMAILS || "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter((e) => e.length > 0),
};
