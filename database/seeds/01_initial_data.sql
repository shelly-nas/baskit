-- Seed Data for Baskit Database
-- Initial categories, stores, and test data

-- ============================================
-- Categories
-- ============================================

INSERT INTO categories (id, name, description, sort_order) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Fruits & Vegetables', 'Fresh produce', 1),
  ('22222222-2222-2222-2222-222222222222', 'Dairy & Eggs', 'Milk, cheese, yogurt, eggs', 2),
  ('33333333-3333-3333-3333-333333333333', 'Meat & Poultry', 'Fresh and packaged meats', 3),
  ('44444444-4444-4444-4444-444444444444', 'Fish & Seafood', 'Fresh and frozen seafood', 4),
  ('55555555-5555-5555-5555-555555555555', 'Bread & Bakery', 'Bread, pastries, baked goods', 5),
  ('66666666-6666-6666-6666-666666666666', 'Pantry Staples', 'Rice, pasta, canned goods, oils', 6),
  ('77777777-7777-7777-7777-777777777777', 'Snacks & Sweets', 'Chips, cookies, candy, chocolate', 7),
  ('88888888-8888-8888-8888-888888888888', 'Beverages', 'Soft drinks, juices, water, coffee, tea', 8),
  ('99999999-9999-9999-9999-999999999999', 'Frozen Foods', 'Frozen meals, vegetables, ice cream', 9),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Household & Cleaning', 'Cleaning supplies, paper products', 10);

-- Subcategories
INSERT INTO categories (name, parent_id, description, sort_order) VALUES
  ('Fresh Fruits', '11111111-1111-1111-1111-111111111111', 'Apples, oranges, bananas, etc.', 1),
  ('Fresh Vegetables', '11111111-1111-1111-1111-111111111111', 'Lettuce, tomatoes, carrots, etc.', 2),
  ('Milk', '22222222-2222-2222-2222-222222222222', 'Regular and plant-based milk', 1),
  ('Cheese', '22222222-2222-2222-2222-222222222222', 'All types of cheese', 2),
  ('Yogurt', '22222222-2222-2222-2222-222222222222', 'Regular and Greek yogurt', 3);

-- ============================================
-- Stores - Dutch Supermarket Chains
-- ============================================

-- Albert Heijn stores
INSERT INTO stores (chain_name, store_name, address, postal_code, city, latitude, longitude, opening_hours) VALUES
  ('Albert Heijn', 'AH Amsterdam Central', 'Nieuwezijds Voorburgwal 226', '1012 RR', 'Amsterdam', 52.373173, 4.891066, 
   '{"monday": {"open": "07:00", "close": "22:00"}, "tuesday": {"open": "07:00", "close": "22:00"}, "wednesday": {"open": "07:00", "close": "22:00"}, "thursday": {"open": "07:00", "close": "22:00"}, "friday": {"open": "07:00", "close": "22:00"}, "saturday": {"open": "08:00", "close": "22:00"}, "sunday": {"open": "10:00", "close": "20:00"}}'),
  ('Albert Heijn', 'AH Rotterdam Centrum', 'Binnenwegplein 35', '3012 KE', 'Rotterdam', 51.921152, 4.473618,
   '{"monday": {"open": "08:00", "close": "22:00"}, "tuesday": {"open": "08:00", "close": "22:00"}, "wednesday": {"open": "08:00", "close": "22:00"}, "thursday": {"open": "08:00", "close": "22:00"}, "friday": {"open": "08:00", "close": "22:00"}, "saturday": {"open": "08:00", "close": "22:00"}, "sunday": {"open": "10:00", "close": "21:00"}}');

-- Jumbo stores
INSERT INTO stores (chain_name, store_name, address, postal_code, city, latitude, longitude, opening_hours) VALUES
  ('Jumbo', 'Jumbo Amsterdam Overtoom', 'Overtoom 127-129', '1054 HG', 'Amsterdam', 52.361389, 4.875278,
   '{"monday": {"open": "08:00", "close": "21:00"}, "tuesday": {"open": "08:00", "close": "21:00"}, "wednesday": {"open": "08:00", "close": "21:00"}, "thursday": {"open": "08:00", "close": "21:00"}, "friday": {"open": "08:00", "close": "21:00"}, "saturday": {"open": "08:00", "close": "21:00"}, "sunday": {"open": "09:00", "close": "20:00"}}'),
  ('Jumbo', 'Jumbo Rotterdam Blijdorp', 'Bergweg 188', '3037 BE', 'Rotterdam', 51.926944, 4.457222,
   '{"monday": {"open": "08:00", "close": "21:00"}, "tuesday": {"open": "08:00", "close": "21:00"}, "wednesday": {"open": "08:00", "close": "21:00"}, "thursday": {"open": "08:00", "close": "21:00"}, "friday": {"open": "08:00", "close": "21:00"}, "saturday": {"open": "08:00", "close": "21:00"}, "sunday": {"open": "09:00", "close": "20:00"}}');

-- Lidl stores
INSERT INTO stores (chain_name, store_name, address, postal_code, city, latitude, longitude, opening_hours) VALUES
  ('Lidl', 'Lidl Amsterdam West', 'Jan van Galenstraat 28', '1051 KM', 'Amsterdam', 52.373889, 4.867222,
   '{"monday": {"open": "08:00", "close": "20:00"}, "tuesday": {"open": "08:00", "close": "20:00"}, "wednesday": {"open": "08:00", "close": "20:00"}, "thursday": {"open": "08:00", "close": "20:00"}, "friday": {"open": "08:00", "close": "20:00"}, "saturday": {"open": "08:00", "close": "20:00"}, "sunday": {"open": "closed", "close": "closed"}}'),
  ('Lidl', 'Lidl Rotterdam Zuid', 'Groene Hilledijk 112', '3074 EK', 'Rotterdam', 51.894722, 4.487500,
   '{"monday": {"open": "08:00", "close": "20:00"}, "tuesday": {"open": "08:00", "close": "20:00"}, "wednesday": {"open": "08:00", "close": "20:00"}, "thursday": {"open": "08:00", "close": "20:00"}, "friday": {"open": "08:00", "close": "20:00"}, "saturday": {"open": "08:00", "close": "20:00"}, "sunday": {"open": "closed", "close": "closed"}}');

-- Dirk stores
INSERT INTO stores (chain_name, store_name, address, postal_code, city, latitude, longitude, opening_hours) VALUES
  ('Dirk', 'Dirk Amsterdam Noord', 'Mosplein 31', '1024 RX', 'Amsterdam', 52.395556, 4.938889,
   '{"monday": {"open": "08:00", "close": "21:00"}, "tuesday": {"open": "08:00", "close": "21:00"}, "wednesday": {"open": "08:00", "close": "21:00"}, "thursday": {"open": "08:00", "close": "21:00"}, "friday": {"open": "08:00", "close": "21:00"}, "saturday": {"open": "08:00", "close": "21:00"}, "sunday": {"open": "10:00", "close": "19:00"}}');

-- ============================================
-- Test Users
-- ============================================

-- Password: 'password123' (hashed with bcrypt)
INSERT INTO users (id, email, password_hash, first_name, last_name, subscription_tier, is_email_verified) VALUES
  ('test1111-1111-1111-1111-111111111111', 'test.user@baskit.nl', '$2b$10$rY8xvXFQqEJvAqYqFWXxweJYLzOJYQZ7Y0fJ7xXvXhXxXxXxXxXxX', 'Test', 'User', 'free', true),
  ('test2222-2222-2222-2222-222222222222', 'premium.user@baskit.nl', '$2b$10$rY8xvXFQqEJvAqYqFWXxweJYLzOJYQZ7Y0fJ7xXvXhXxXxXxXxXxX', 'Premium', 'User', 'premium', true);

-- User preferences
INSERT INTO user_preferences (user_id, default_optimization, enable_notifications) VALUES
  ('test1111-1111-1111-1111-111111111111', 'cheapest', true),
  ('test2222-2222-2222-2222-222222222222', 'balanced', true);

-- ============================================
-- Sample Products
-- ============================================

-- Milk products
INSERT INTO products (name, category_id, brand, base_unit) VALUES
  ('Whole Milk', (SELECT id FROM categories WHERE name = 'Milk'), 'Campina', 'liter'),
  ('Semi-Skimmed Milk', (SELECT id FROM categories WHERE name = 'Milk'), 'Campina', 'liter'),
  ('Oat Milk', (SELECT id FROM categories WHERE name = 'Milk'), 'Alpro', 'liter');

-- Product variations
INSERT INTO product_variations (product_id, size, unit_amount, unit_type) VALUES
  ((SELECT id FROM products WHERE name = 'Whole Milk'), '1L', 1.0, 'liter'),
  ((SELECT id FROM products WHERE name = 'Whole Milk'), '2L', 2.0, 'liter'),
  ((SELECT id FROM products WHERE name = 'Semi-Skimmed Milk'), '1L', 1.0, 'liter'),
  ((SELECT id FROM products WHERE name = 'Oat Milk'), '1L', 1.0, 'liter');

-- ============================================
-- Sample Prices
-- ============================================

-- Whole Milk 1L prices at different stores
INSERT INTO prices (store_id, product_variation_id, price, unit_price, unit_type) VALUES
  ((SELECT id FROM stores WHERE store_name = 'AH Amsterdam Central'), (SELECT id FROM product_variations WHERE size = '1L' AND product_id = (SELECT id FROM products WHERE name = 'Whole Milk')), 1.49, 1.49, 'liter'),
  ((SELECT id FROM stores WHERE store_name = 'Jumbo Amsterdam Overtoom'), (SELECT id FROM product_variations WHERE size = '1L' AND product_id = (SELECT id FROM products WHERE name = 'Whole Milk')), 1.39, 1.39, 'liter'),
  ((SELECT id FROM stores WHERE store_name = 'Lidl Amsterdam West'), (SELECT id FROM product_variations WHERE size = '1L' AND product_id = (SELECT id FROM products WHERE name = 'Whole Milk')), 1.29, 1.29, 'liter');

-- Comments
COMMENT ON TABLE schema_migrations IS 'Seed data loaded for initial testing and development';
