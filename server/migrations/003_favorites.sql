-- Favorite items ("vaste boodschappen") per user, put on a list with one tap.
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    quantity VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_favorites_user_name ON favorites (user_id, LOWER(name));
