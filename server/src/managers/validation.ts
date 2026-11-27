import crypto from "crypto";
import { badRequest } from "../middleware/errors";

// Checks for request bodies shared by the managers.

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** A UUID made on the device, or a new one. */
export function idOrNew(value: unknown): string {
  if (value === undefined || value === null) return crypto.randomUUID();
  if (typeof value !== "string" || !UUID_PATTERN.test(value)) throw badRequest("Invalid id");
  return value.toLowerCase();
}

export function requiredText(value: unknown, field: string, max: number): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length === 0) throw badRequest(`${field} cannot be empty`);
  if (text.length > max) throw badRequest(`${field} is too long`);
  return text;
}

export function optionalText(value: unknown, field: string, max: number): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "string") throw badRequest(`Invalid ${field}`);
  const text = value.trim();
  if (text.length > max) throw badRequest(`${field} is too long`);
  return text.length === 0 ? null : text;
}

export function isUuid(value: string): boolean {
  return UUID_PATTERN.test(value);
}

/** A UUID in the path. */
export function requiredId(value: unknown): string {
  if (typeof value !== "string" || !isUuid(value)) throw badRequest("Invalid id");
  return value.toLowerCase();
}
