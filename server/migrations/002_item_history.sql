-- Items each user added, for suggestions when adding items (FR-003). Kept
-- when items are removed from a list; one row per name in any case.
CREATE TABLE IF NOT EXISTS item_history (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name_key TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    times_added INTEGER NOT NULL DEFAULT 1,
    last_added_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, name_key)
);

-- Start from the items already in each owner's lists.
INSERT INTO item_history (user_id, name_key, name, times_added, last_added_at)
SELECT l.owner_id, LOWER(TRIM(i.name)), MAX(TRIM(i.name)), COUNT(*), MAX(i.created_at)
FROM list_items i
JOIN lists l ON l.id = i.list_id
GROUP BY l.owner_id, LOWER(TRIM(i.name))
ON CONFLICT (user_id, name_key) DO NOTHING;
