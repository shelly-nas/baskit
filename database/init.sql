-- Baskit Database Initialization Script
-- PostgreSQL 15+
-- This script is automatically executed when the Docker container is first created
-- It sets up all extensions, functions, and tables for the Baskit application

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For trigram text search

-- Note: earthdistance requires cube extension
CREATE EXTENSION IF NOT EXISTS "cube";
CREATE EXTENSION IF NOT EXISTS "earthdistance";

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

COMMENT ON FUNCTION update_updated_at_column() IS 'Automatically updates the updated_at timestamp on row modification';

-- ============================================================================
-- SCHEMA: USER SERVICE
-- Tables: users, user_preferences
-- ============================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    profile_picture_url VARCHAR(500),
    is_email_verified BOOLEAN DEFAULT FALSE,
    status VARCHAR(25) DEFAULT 'pending_verification' CHECK (status IN ('active', 'locked', 'pending_verification', 'deleted')),
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium')),
    subscription_start_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    last_login_at TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    default_optimization VARCHAR(20) DEFAULT 'cheapest' CHECK (default_optimization IN ('cheapest', 'fastest', 'balanced')),
    enable_notifications BOOLEAN DEFAULT TRUE,
    notification_frequency VARCHAR(20) DEFAULT 'immediate' CHECK (notification_frequency IN ('immediate', 'daily', 'weekly')),
    default_location JSONB,
    preferred_stores JSONB DEFAULT '[]',
    accessibility_mode BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) DEFAULT 'nl',
    currency VARCHAR(3) DEFAULT 'EUR',
    distance_unit VARCHAR(10) DEFAULT 'km' CHECK (distance_unit IN ('km', 'mi')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription_tier ON users(subscription_tier);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- Triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE users IS 'Core user accounts and authentication data';
COMMENT ON TABLE user_preferences IS 'User-specific preferences and settings';

-- ============================================================================
-- SCHEMA: PRODUCT SERVICE
-- Tables: categories, products, product_variations
-- ============================================================================

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    description TEXT,
    icon_url VARCHAR(255),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    brand VARCHAR(100),
    description TEXT,
    base_unit VARCHAR(20),
    image_url VARCHAR(255),
    barcode VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product variations table
CREATE TABLE IF NOT EXISTS product_variations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku VARCHAR(100),
    size VARCHAR(50),
    unit_amount DECIMAL(10, 3),
    unit_type VARCHAR(20),
    package_type VARCHAR(50),
    barcode VARCHAR(50),
    image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_categories_sort_order ON categories(sort_order);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_name_trgm ON products USING gin(name gin_trgm_ops);
CREATE INDEX idx_product_variations_product_id ON product_variations(product_id);
CREATE INDEX idx_product_variations_sku ON product_variations(sku);
CREATE INDEX idx_product_variations_barcode ON product_variations(barcode);

-- Triggers
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_variations_updated_at BEFORE UPDATE ON product_variations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE categories IS 'Product categories with hierarchical support';
COMMENT ON TABLE products IS 'Core product catalog';
COMMENT ON TABLE product_variations IS 'Different sizes and packages of products';

-- ============================================================================
-- SCHEMA: LIST SERVICE
-- Tables: lists, list_items, list_sharing, list_versions
-- ============================================================================

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
    custom_item_name VARCHAR(255),
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

-- List versions table
CREATE TABLE IF NOT EXISTS list_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    snapshot JSONB NOT NULL,
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

-- ============================================================================
-- SCHEMA: STORE SERVICE
-- Tables: stores, store_layouts
-- ============================================================================

-- Stores table
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chain_name VARCHAR(100) NOT NULL,
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
    opening_hours JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Store layouts table
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

-- ============================================================================
-- SCHEMA: PRICE SERVICE
-- Tables: prices, price_history, promotions
-- ============================================================================

-- Prices table
CREATE TABLE IF NOT EXISTS prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_variation_id UUID NOT NULL REFERENCES product_variations(id) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'EUR',
    unit_price DECIMAL(10, 2),
    unit_type VARCHAR(20),
    is_available BOOLEAN DEFAULT TRUE,
    last_scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_url VARCHAR(500),
    confidence_score DECIMAL(3, 2) DEFAULT 1.00,
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
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) CHECK (discount_type IN ('percentage', 'fixed_amount', 'buy_x_get_y', 'multibuy')),
    discount_value DECIMAL(10, 2),
    discount_conditions JSONB,
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

-- ============================================================================
-- SCHEMA: SUPPORTING TABLES
-- Tables: favorites, savings_tracking, notifications, shopping_routes
-- ============================================================================

-- Favorites table
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_variation_id UUID NOT NULL REFERENCES product_variations(id) ON DELETE CASCADE,
    category_name VARCHAR(100),
    price_threshold DECIMAL(10, 2),
    discount_threshold INTEGER,
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
    potential_spend DECIMAL(10, 2) NOT NULL,
    amount_saved DECIMAL(10, 2) NOT NULL,
    savings_percentage DECIMAL(5, 2),
    stores_visited JSONB,
    optimization_type VARCHAR(20) CHECK (optimization_type IN ('cheapest', 'fastest', 'balanced', 'manual')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id UUID,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    sent_via JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Shopping routes table
CREATE TABLE IF NOT EXISTS shopping_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    list_id UUID NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
    route_type VARCHAR(20) CHECK (route_type IN ('cheapest', 'fastest', 'balanced')),
    total_cost DECIMAL(10, 2),
    total_distance DECIMAL(10, 2),
    total_time INTEGER,
    stores_order JSONB NOT NULL,
    route_details JSONB,
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

-- ============================================================================
-- SCHEMA: VERIFICATION & SECURITY
-- Tables: verification_tokens, password_reset_tokens, password_history, audit_logs
-- ============================================================================

-- Verification tokens table
CREATE TABLE IF NOT EXISTS verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    token_type VARCHAR(20) DEFAULT 'email_verification' CHECK (token_type IN ('email_verification', 'email_change')),
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Password reset tokens table
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Password history table
CREATE TABLE IF NOT EXISTS password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL,
    event_description TEXT,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_verification_tokens_user_id ON verification_tokens(user_id);
CREATE INDEX idx_verification_tokens_token ON verification_tokens(token);
CREATE INDEX idx_verification_tokens_expires_at ON verification_tokens(expires_at);
CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX idx_password_reset_tokens_expires_at ON password_reset_tokens(expires_at);
CREATE INDEX idx_password_history_user_id ON password_history(user_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Comments
COMMENT ON TABLE verification_tokens IS 'Email verification and email change verification tokens';
COMMENT ON TABLE password_reset_tokens IS 'Password reset tokens with expiration';
COMMENT ON TABLE password_history IS 'Password history for preventing reuse of recent passwords';
COMMENT ON TABLE audit_logs IS 'Security audit log for authentication events';

-- ============================================================================
-- INITIALIZATION COMPLETE
-- ============================================================================

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Baskit database initialization completed successfully';
    RAISE NOTICE 'All tables, indexes, and triggers have been created';
END $$;
