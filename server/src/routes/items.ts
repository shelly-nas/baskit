import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { handle } from "../middleware/errors";
import * as items from "../managers/itemManager";

const router = Router();
router.use(requireAuth);

router.get(
  "/suggestions",
  handle(async (req, res) => res.json(await items.suggestions(req.user!.id, req.query.q, req.query.limit)))
);

export default router;
