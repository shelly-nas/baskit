-- Store Service Schema
-- Tables: stores, store_layouts

-- Stores table
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chain_name VARCHAR(100) NOT NULL, -- e.g., 'Albert Heijn', 'Jumbo', 'Lidl'
    store_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    postal_code VARCHAR(20),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(2) DEFAULT 'NL',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    website_url VARCHAR(255),
    opening_hours JSONB, -- {monday: {open: "08:00", close: "20:00"}, ...}
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Store layouts table (for in-store navigation)
CREATE TABLE IF NOT EXISTS store_layouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    aisle_number VARCHAR(20),
    section_name VARCHAR(100),
    sort_order INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(store_id, category_id)
);

-- Indexes
CREATE INDEX idx_stores_chain_name ON stores(chain_name);
CREATE INDEX idx_stores_city ON stores(city);
CREATE INDEX idx_stores_postal_code ON stores(postal_code);
CREATE INDEX idx_stores_location ON stores USING gist(ll_to_earth(latitude, longitude));
CREATE INDEX idx_stores_is_active ON stores(is_active);
CREATE INDEX idx_store_layouts_store_id ON store_layouts(store_id);
CREATE INDEX idx_store_layouts_category_id ON store_layouts(category_id);
CREATE INDEX idx_store_layouts_sort_order ON store_layouts(sort_order);

-- Triggers
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_store_layouts_updated_at BEFORE UPDATE ON store_layouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE stores IS 'Physical store locations';
COMMENT ON TABLE store_layouts IS 'Category placement within stores for navigation';
COMMENT ON COLUMN stores.chain_name IS 'Supermarket chain: Albert Heijn, Jumbo, Dirk, Plus, Hoogvliet, Lidl';
COMMENT ON COLUMN stores.opening_hours IS 'JSON object with daily opening hours';
COMMENT ON COLUMN store_layouts.sort_order IS 'Order of categories for efficient shopping route';
