import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { handle } from "../middleware/errors";
import * as lists from "../managers/listManager";

const router = Router();
router.use(requireAuth);

router.get("/", handle(async (req, res) => res.json(await lists.getLists(req.user!.id))));
router.post("/", handle(async (req, res) => res.status(201).json(await lists.createList(req.user!.id, req.body))));
router.post("/import", handle(async (req, res) => res.json(await lists.importLists(req.user!.id, req.body))));

router.get("/:id", handle(async (req, res) => res.json(await lists.getList(req.params.id, req.user!.id))));
router.patch("/:id", handle(async (req, res) => res.json(await lists.renameList(req.params.id, req.user!.id, req.body))));
router.delete(
  "/:id",
  handle(async (req, res) => {
    await lists.deleteList(req.params.id, req.user!.id);
    res.status(204).end();
  })
);

router.post(
  "/:id/items",
  handle(async (req, res) => res.status(201).json(await lists.addItem(req.params.id, req.user!.id, req.body)))
);
router.patch(
  "/:id/items/:itemId",
  handle(async (req, res) =>
    res.json(await lists.updateItem(req.params.id, req.params.itemId, req.user!.id, req.body))
  )
);
router.delete(
  "/:id/items/:itemId",
  handle(async (req, res) => {
    await lists.deleteItem(req.params.id, req.params.itemId, req.user!.id);
    res.status(204).end();
  })
);

router.post(
  "/:id/members",
  handle(async (req, res) => res.json(await lists.addMember(req.params.id, req.user!.id, req.body)))
);
router.delete(
  "/:id/members/:memberId",
  handle(async (req, res) => {
    await lists.removeMember(req.params.id, req.user!.id, req.params.memberId);
    res.status(204).end();
  })
);

export default router;
