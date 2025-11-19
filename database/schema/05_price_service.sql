-- Price Service Schema
-- Tables: prices, price_history, promotions

-- Prices table (current prices)
CREATE TABLE IF NOT EXISTS prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_variation_id UUID NOT NULL REFERENCES product_variations(id) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2), -- Before discount
    currency VARCHAR(3) DEFAULT 'EUR',
    unit_price DECIMAL(10, 2), -- Price per standard unit (e.g., per kg)
    unit_type VARCHAR(20), -- e.g., 'kg', 'liter'
    is_available BOOLEAN DEFAULT TRUE,
    last_scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_url VARCHAR(500),
    confidence_score DECIMAL(3, 2) DEFAULT 1.00, -- Data accuracy confidence
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(store_id, product_variation_id)
);

-- Price history table
CREATE TABLE IF NOT EXISTS price_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_variation_id UUID NOT NULL REFERENCES product_variations(id) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'EUR',
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Promotions table
CREATE TABLE IF NOT EXISTS promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_variation_id UUID REFERENCES product_variations(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE, -- For category-wide promotions
    title VARCHAR(255) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) CHECK (discount_type IN ('percentage', 'fixed_amount', 'buy_x_get_y', 'multibuy')),
    discount_value DECIMAL(10, 2),
    discount_conditions JSONB, -- e.g., {buy: 2, get: 1, min_quantity: 3}
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    promotion_code VARCHAR(50),
    image_url VARCHAR(255),
    source_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (product_variation_id IS NOT NULL OR category_id IS NOT NULL)
);

-- Indexes
CREATE INDEX idx_prices_store_id ON prices(store_id);
CREATE INDEX idx_prices_product_variation_id ON prices(product_variation_id);
CREATE INDEX idx_prices_last_scraped_at ON prices(last_scraped_at);
CREATE INDEX idx_prices_store_product ON prices(store_id, product_variation_id);
CREATE INDEX idx_price_history_store_id ON price_history(store_id);
CREATE INDEX idx_price_history_product_variation_id ON price_history(product_variation_id);
CREATE INDEX idx_price_history_effective_from ON price_history(effective_from);
CREATE INDEX idx_price_history_store_product_date ON price_history(store_id, product_variation_id, effective_from DESC);
CREATE INDEX idx_promotions_store_id ON promotions(store_id);
CREATE INDEX idx_promotions_product_variation_id ON promotions(product_variation_id);
CREATE INDEX idx_promotions_category_id ON promotions(category_id);
CREATE INDEX idx_promotions_valid_dates ON promotions(valid_from, valid_to);
CREATE INDEX idx_promotions_is_active ON promotions(is_active);

-- Triggers
CREATE TRIGGER update_prices_updated_at BEFORE UPDATE ON prices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON promotions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE prices IS 'Current product prices at stores';
COMMENT ON TABLE price_history IS 'Historical price data for trend analysis';
COMMENT ON TABLE promotions IS 'Store promotions and discounts';
COMMENT ON COLUMN prices.confidence_score IS 'Data accuracy confidence (0.00 to 1.00)';
COMMENT ON COLUMN prices.unit_price IS 'Normalized price per standard unit';
COMMENT ON COLUMN promotions.discount_type IS 'Type of discount: percentage, fixed_amount, buy_x_get_y, multibuy';
COMMENT ON COLUMN promotions.discount_conditions IS 'JSON with promotion conditions';
