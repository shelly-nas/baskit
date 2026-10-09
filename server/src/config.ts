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

export const config = {
  port: parseInt(process.env.SERVER_PORT || "3000", 10),
  isProduction,
  jwtSecret: jwtSecret(),
  /** How long a sign-in lasts. */
  tokenTtl: process.env.TOKEN_TTL || "30d",
  /** Accounts with these emails get the admin role when they register or sign in. */
  adminEmails: (process.env.ADMIN_EMAILS || "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter((e) => e.length > 0),
};
