-- Supporting Tables Schema
-- Tables: favorites, savings_tracking, notifications, shopping_routes

-- Favorites table
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_variation_id UUID NOT NULL REFERENCES product_variations(id) ON DELETE CASCADE,
    category_name VARCHAR(100), -- User-defined category (e.g., 'pantry', 'weekly essentials')
    price_threshold DECIMAL(10, 2), -- Alert when price drops below this
    discount_threshold INTEGER, -- Alert when discount is at least this percentage
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_variation_id)
);

-- Savings tracking table
CREATE TABLE IF NOT EXISTS savings_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    list_id UUID REFERENCES lists(id) ON DELETE SET NULL,
    shopping_date DATE NOT NULL,
    total_spent DECIMAL(10, 2) NOT NULL,
    potential_spend DECIMAL(10, 2) NOT NULL, -- What would have been spent without optimization
    amount_saved DECIMAL(10, 2) NOT NULL,
    savings_percentage DECIMAL(5, 2),
    stores_visited JSONB, -- Array of store IDs visited
    optimization_type VARCHAR(20) CHECK (optimization_type IN ('cheapest', 'fastest', 'balanced', 'manual')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- e.g., 'price_alert', 'list_shared', 'promotion'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50), -- e.g., 'product', 'list', 'promotion'
    related_entity_id UUID,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    sent_via JSONB DEFAULT '[]', -- Array of channels: ['push', 'email', 'in_app']
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Shopping routes table (saved optimized routes)
CREATE TABLE IF NOT EXISTS shopping_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    route_type VARCHAR(20) CHECK (route_type IN ('cheapest', 'fastest', 'balanced')),
    total_cost DECIMAL(10, 2),
    total_distance DECIMAL(10, 2), -- in km
    total_time INTEGER, -- in minutes
    stores_order JSONB NOT NULL, -- Ordered array of store IDs with items to buy
    route_details JSONB, -- Navigation details, coordinates, etc.
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_product_variation_id ON favorites(product_variation_id);
CREATE INDEX idx_favorites_is_active ON favorites(is_active);
CREATE INDEX idx_savings_tracking_user_id ON savings_tracking(user_id);
CREATE INDEX idx_savings_tracking_shopping_date ON savings_tracking(shopping_date);
CREATE INDEX idx_savings_tracking_list_id ON savings_tracking(list_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at);
CREATE INDEX idx_shopping_routes_user_id ON shopping_routes(user_id);
CREATE INDEX idx_shopping_routes_list_id ON shopping_routes(list_id);
CREATE INDEX idx_shopping_routes_is_completed ON shopping_routes(is_completed);

-- Triggers
CREATE TRIGGER update_favorites_updated_at BEFORE UPDATE ON favorites
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_savings_tracking_updated_at BEFORE UPDATE ON savings_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_routes_updated_at BEFORE UPDATE ON shopping_routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE favorites IS 'User favorite products with price alert thresholds';
COMMENT ON TABLE savings_tracking IS 'Historical savings data for analytics and motivation';
COMMENT ON TABLE notifications IS 'User notifications for various events';
COMMENT ON TABLE shopping_routes IS 'Saved and optimized shopping routes';
COMMENT ON COLUMN favorites.price_threshold IS 'Alert when price drops below this amount';
COMMENT ON COLUMN favorites.discount_threshold IS 'Alert when discount percentage meets or exceeds this';
COMMENT ON COLUMN savings_tracking.potential_spend IS 'Baseline cost without optimization';
COMMENT ON COLUMN notifications.sent_via IS 'JSON array of notification channels used';
COMMENT ON COLUMN shopping_routes.stores_order IS 'JSON array with shopping sequence';
