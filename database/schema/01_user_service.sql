-- User Service Schema
-- Tables: users, user_preferences

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium')),
    subscription_start_date TIMESTAMP,
    subscription_end_date TIMESTAMP,
    last_login_at TIMESTAMP,
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
    default_location JSONB, -- {latitude, longitude, address}
    preferred_stores JSONB DEFAULT '[]', -- Array of store IDs
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
COMMENT ON COLUMN users.subscription_tier IS 'User subscription level: free or premium';
COMMENT ON COLUMN user_preferences.default_optimization IS 'Default route optimization preference';
COMMENT ON COLUMN user_preferences.preferred_stores IS 'JSON array of preferred store UUIDs';
