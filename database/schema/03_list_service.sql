-- List Service Schema
-- Tables: lists, list_items, list_sharing, list_versions

-- Lists table
CREATE TABLE IF NOT EXISTS lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_shared BOOLEAN DEFAULT FALSE,
    is_template BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
    last_used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1
);

-- List items table
CREATE TABLE IF NOT EXISTS list_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    product_variation_id UUID REFERENCES product_variations(id) ON DELETE SET NULL,
    custom_item_name VARCHAR(255), -- For items not in product catalog
    quantity DECIMAL(10, 2) DEFAULT 1,
    unit VARCHAR(20),
    notes TEXT,
    is_checked BOOLEAN DEFAULT FALSE,
    checked_at TIMESTAMP,
    checked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- List sharing table
CREATE TABLE IF NOT EXISTS list_sharing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) DEFAULT 'view' CHECK (permission_level IN ('view', 'edit', 'admin')),
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    accepted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(list_id, user_id)
);

-- List versions table (for conflict resolution and history)
CREATE TABLE IF NOT EXISTS list_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    snapshot JSONB NOT NULL, -- Complete list state at this version
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    change_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(list_id, version_number)
);

-- Indexes
CREATE INDEX idx_lists_owner_id ON lists(owner_id);
CREATE INDEX idx_lists_status ON lists(status);
CREATE INDEX idx_lists_last_used_at ON lists(last_used_at);
CREATE INDEX idx_lists_is_shared ON lists(is_shared);
CREATE INDEX idx_list_items_list_id ON list_items(list_id);
CREATE INDEX idx_list_items_product_variation_id ON list_items(product_variation_id);
CREATE INDEX idx_list_items_sort_order ON list_items(sort_order);
CREATE INDEX idx_list_items_is_checked ON list_items(is_checked);
CREATE INDEX idx_list_sharing_list_id ON list_sharing(list_id);
CREATE INDEX idx_list_sharing_user_id ON list_sharing(user_id);
CREATE INDEX idx_list_versions_list_id ON list_versions(list_id);

-- Triggers
CREATE TRIGGER update_lists_updated_at BEFORE UPDATE ON lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_list_items_updated_at BEFORE UPDATE ON list_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_list_sharing_updated_at BEFORE UPDATE ON list_sharing
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE lists IS 'Shopping lists owned by users';
COMMENT ON TABLE list_items IS 'Items within shopping lists';
COMMENT ON TABLE list_sharing IS 'Shared access permissions for lists';
COMMENT ON TABLE list_versions IS 'Version history for conflict resolution';
COMMENT ON COLUMN list_items.custom_item_name IS 'Used when product is not in catalog';
COMMENT ON COLUMN list_sharing.permission_level IS 'Access level: view, edit, or admin';
COMMENT ON COLUMN list_versions.snapshot IS 'Complete list state as JSON';
