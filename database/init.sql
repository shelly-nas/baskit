-- Baskit schema: accounts and shopping lists.
--
-- Runs once, on the first start of an empty database volume (postgres image
-- entrypoint). Every later schema change goes into server/migrations/, which
-- the server applies on startup.
--
-- Supermarket products and prices are not stored here: they come from the
-- supermarket-scraper public API.

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at TIMESTAMPTZ
);

-- Emails are compared case-insensitively.
CREATE UNIQUE INDEX idx_users_email ON users (LOWER(email));

CREATE TABLE lists (
    -- Client generated, so lists made offline keep their id when uploaded.
    id UUID PRIMARY KEY,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_lists_owner ON lists(owner_id);

CREATE TABLE list_items (
    id UUID PRIMARY KEY,
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    quantity VARCHAR(50),
    category VARCHAR(255),
    is_completed BOOLEAN NOT NULL DEFAULT false,
    -- Snapshot of the supermarket offer the item was added from, if any.
    offer JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_list_items_list ON list_items(list_id, created_at);

-- People a list is shared with. The owner is not a member row.
CREATE TABLE list_members (
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (list_id, user_id)
);
CREATE INDEX idx_list_members_user ON list_members(user_id);

COMMENT ON TABLE users IS 'Baskit accounts; role admin can manage users';
COMMENT ON TABLE lists IS 'Shopping lists, owned by one user and optionally shared';
COMMENT ON TABLE list_items IS 'Items on a shopping list';
COMMENT ON TABLE list_members IS 'Users a list is shared with (can edit, cannot delete or share)';
