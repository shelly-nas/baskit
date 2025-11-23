-- Seed Data for Baskit Database
-- Initial test data for development and testing

-- ============================================================================
-- DEFAULT TEST USERS
-- ============================================================================
-- These users are pre-verified and active for easy testing
-- Password for all test users: TestPassword123!
-- Hash: $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIq8z.KhOK

DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Creating default test users...';
    RAISE NOTICE '===========================================';

    -- ========================================
    -- Test User 1: Free Tier
    -- ========================================
    INSERT INTO users (
        id,
        email,
        password_hash,
        display_name,
        first_name,
        last_name,
        phone_number,
        is_email_verified,
        status,
        subscription_tier,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000001',
        'test@baskit.app',
        '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIq8z.KhOK',
        'Test User',
        'Test',
        'User',
        '+31612345678',
        TRUE,
        'active',
        'free',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (email) DO NOTHING;

    INSERT INTO user_preferences (
        user_id,
        default_optimization,
        enable_notifications,
        notification_frequency,
        default_location,
        preferred_stores,
        accessibility_mode,
        language,
        currency,
        distance_unit,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000001',
        'cheapest',
        TRUE,
        'immediate',
        '{"latitude": 52.3676, "longitude": 4.9041, "address": "Amsterdam, Netherlands"}',
        '[]',
        FALSE,
        'nl',
        'EUR',
        'km',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (user_id) DO NOTHING;

    RAISE NOTICE '✓ Free tier user: test@baskit.app';

    -- ========================================
    -- Test User 2: Premium Tier
    -- ========================================
    INSERT INTO users (
        id,
        email,
        password_hash,
        display_name,
        first_name,
        last_name,
        phone_number,
        is_email_verified,
        status,
        subscription_tier,
        subscription_start_date,
        subscription_end_date,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000002',
        'premium@baskit.app',
        '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIq8z.KhOK',
        'Premium User',
        'Premium',
        'User',
        '+31687654321',
        TRUE,
        'active',
        'premium',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '1 year',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (email) DO NOTHING;

    INSERT INTO user_preferences (
        user_id,
        default_optimization,
        enable_notifications,
        notification_frequency,
        default_location,
        preferred_stores,
        accessibility_mode,
        language,
        currency,
        distance_unit,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000002',
        'balanced',
        TRUE,
        'daily',
        '{"latitude": 51.9225, "longitude": 4.47917, "address": "Rotterdam, Netherlands"}',
        '[]',
        FALSE,
        'nl',
        'EUR',
        'km',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (user_id) DO NOTHING;

    RAISE NOTICE '✓ Premium tier user: premium@baskit.app';

    -- ========================================
    -- Test User 3: Unverified User
    -- ========================================
    INSERT INTO users (
        id,
        email,
        password_hash,
        display_name,
        first_name,
        last_name,
        is_email_verified,
        status,
        subscription_tier,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000003',
        'unverified@baskit.app',
        '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIq8z.KhOK',
        'Unverified User',
        'Unverified',
        'User',
        FALSE,
        'pending_verification',
        'free',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (email) DO NOTHING;

    INSERT INTO user_preferences (
        user_id,
        default_optimization,
        enable_notifications,
        notification_frequency,
        language,
        currency,
        distance_unit,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000003',
        'cheapest',
        TRUE,
        'immediate',
        'nl',
        'EUR',
        'km',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (user_id) DO NOTHING;

    RAISE NOTICE '✓ Unverified user: unverified@baskit.app';

    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Test users created successfully!';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'All test accounts use password: TestPassword123!';
    RAISE NOTICE '  ';
    RAISE NOTICE 'Available test accounts:';
    RAISE NOTICE '  1. test@baskit.app (Free tier, verified)';
    RAISE NOTICE '  2. premium@baskit.app (Premium tier, verified)';
    RAISE NOTICE '  3. unverified@baskit.app (Free tier, unverified)';
    RAISE NOTICE '===========================================';
END $$;
