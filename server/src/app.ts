import express from "express";
import helmet from "helmet";
import cors from "cors";
import authRoutes from "./routes/auth";
import listRoutes from "./routes/lists";
import adminRoutes from "./routes/admin";
import { errorHandler } from "./middleware/errors";

export function createApp(): express.Express {
  const app = express();
  // Behind nginx and Traefik: use X-Forwarded-For for the client IP (rate limit).
  app.set("trust proxy", 2);
  app.use(helmet());
  // The web app is served from the same origin through nginx; CORS only
  // matters for local development (flutter run -d chrome).
  app.use(cors());
  app.use(express.json({ limit: "1mb" }));

  app.get("/api/health", (req, res) => res.json({ status: "healthy" }));
  app.use("/api/auth", authRoutes);
  app.use("/api/lists", listRoutes);
  app.use("/api/admin", adminRoutes);

  app.use("/api", (req, res) => res.status(404).json({ error: "Not found" }));
  app.use(errorHandler);
  return app;
}
