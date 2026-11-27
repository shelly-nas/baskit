import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { handle } from "../middleware/errors";
import * as favorites from "../managers/favoriteManager";

const router = Router();
router.use(requireAuth);

router.get("/", handle(async (req, res) => res.json(await favorites.list(req.user!.id))));
router.post("/", handle(async (req, res) => res.status(201).json(await favorites.add(req.user!.id, req.body))));
router.delete(
  "/:id",
  handle(async (req, res) => {
    await favorites.remove(req.user!.id, req.params.id);
    res.status(204).end();
  })
);

export default router;
