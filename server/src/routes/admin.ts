import { Router } from "express";
import { requireAdmin, requireAuth } from "../middleware/auth";
import { handle } from "../middleware/errors";
import * as users from "../managers/userManager";

const router = Router();
router.use(requireAuth, requireAdmin);

router.get("/stats", handle(async (req, res) => res.json(await users.stats())));
router.get("/users", handle(async (req, res) => res.json(await users.listUsers())));
router.patch(
  "/users/:id",
  handle(async (req, res) => res.json(await users.adminUpdateUser(req.user!.id, req.params.id, req.body)))
);

export default router;
