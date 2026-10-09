import { Router } from "express";
import { requireAuth, signToken } from "../middleware/auth";
import { handle } from "../middleware/errors";
import { rateLimit } from "../middleware/rateLimit";
import * as users from "../managers/userManager";

const router = Router();

// 20 attempts per 15 minutes per IP for the endpoints that take a password.
const limited = rateLimit(20, 15 * 60 * 1000);

router.post(
  "/register",
  limited,
  handle(async (req, res) => {
    const user = await users.register(req.body);
    res.status(201).json({ token: signToken(user.id), user });
  })
);

router.post(
  "/login",
  limited,
  handle(async (req, res) => {
    const user = await users.login(req.body);
    res.json({ token: signToken(user.id), user });
  })
);

router.get(
  "/me",
  requireAuth,
  handle(async (req, res) => {
    res.json(await users.getUser(req.user!.id));
  })
);

router.patch(
  "/me",
  requireAuth,
  limited,
  handle(async (req, res) => {
    res.json(await users.updateMe(req.user!.id, req.body));
  })
);

export default router;
