import { NextFunction, Request, Response } from "express";

/** An error with an HTTP status that is safe to show to the client. */
export class HttpError extends Error {
  constructor(
    public status: number,
    message: string
  ) {
    super(message);
  }
}

export const badRequest = (message: string) => new HttpError(400, message);
export const notFound = (message = "Not found") => new HttpError(404, message);
export const forbidden = (message = "Not allowed") => new HttpError(403, message);

/** Wraps an async route handler so rejections reach the error handler. */
export const handle =
  (fn: (req: Request, res: Response) => Promise<unknown>) =>
  (req: Request, res: Response, next: NextFunction) => {
    fn(req, res).catch(next);
  };

export function errorHandler(error: any, req: Request, res: Response, _next: NextFunction): void {
  if (error instanceof HttpError) {
    res.status(error.status).json({ error: error.message });
    return;
  }
  // Malformed JSON body.
  if (error?.type === "entity.parse.failed") {
    res.status(400).json({ error: "Invalid JSON" });
    return;
  }
  // Postgres: invalid uuid input.
  if (error?.code === "22P02") {
    res.status(400).json({ error: "Invalid id" });
    return;
  }
  console.error(`${req.method} ${req.path} failed:`, error);
  res.status(500).json({ error: "Internal server error" });
}
