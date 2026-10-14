-- Demo data for local development and acceptance. NEVER loaded in production.
--
-- Loaded into the freshly reset acc database by .github/workflows/acc.yml and
-- mounted as 02-seed-demo.sql by docker-compose.yml locally. The database
-- image (database/Dockerfile) copies init.sql by name and deliberately does
-- not copy this file, so there is no path by which it reaches production,
-- where accounts and lists are real and persistent.
--
-- Guarded: a no-op when any account already exists, so replaying it by hand
-- against a live database never touches real rows.
--
-- Every demo account signs in with the password: baskit-demo
--   admin@baskit.demo  Demo Admin   admin
--   anna@baskit.demo   Anna         owns "Weekboodschappen" (shared with Bram), "Barbecue zaterdag"
--   bram@baskit.demo   Bram         owns "Drogisterij", member of "Weekboodschappen"
--   cees@baskit.demo   Cees         disabled account
DO $demo$
DECLARE
  -- bcrypt hash of "baskit-demo" (cost 10)
  demo_hash CONSTANT TEXT := '$2b$10$kvrcLqguLtTNMNbnZL5POO0T7w187/swB6cFolT9XfOL3VMdqr8Qq';
BEGIN

IF EXISTS (SELECT 1 FROM users LIMIT 1) THEN
  RAISE NOTICE 'seed-demo.sql: accounts already present, skipping demo data.';
  RETURN;
END IF;

INSERT INTO users (id, email, display_name, password_hash, role, is_active, created_at, last_login_at) VALUES
  ('00000000-0000-4000-8000-000000000001', 'admin@baskit.demo', 'Demo Admin', demo_hash, 'admin', true,  now() - interval '60 days', now() - interval '1 day'),
  ('00000000-0000-4000-8000-000000000002', 'anna@baskit.demo',  'Anna',       demo_hash, 'user',  true,  now() - interval '40 days', now() - interval '2 hours'),
  ('00000000-0000-4000-8000-000000000003', 'bram@baskit.demo',  'Bram',       demo_hash, 'user',  true,  now() - interval '35 days', now() - interval '3 days'),
  ('00000000-0000-4000-8000-000000000004', 'cees@baskit.demo',  'Cees',       demo_hash, 'user',  false, now() - interval '90 days', now() - interval '80 days');

INSERT INTO lists (id, owner_id, name, created_at, updated_at) VALUES
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'Weekboodschappen',  now() - interval '6 days', now() - interval '2 hours'),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', 'Barbecue zaterdag', now() - interval '3 days', now() - interval '1 day'),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000003', 'Drogisterij',       now() - interval '10 days', now() - interval '5 days');

INSERT INTO list_members (list_id, user_id, added_at) VALUES
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000003', now() - interval '5 days');

-- Offer snapshots use the same JSON shape as the app (ListItemOffer). The
-- product ids are illustrative; acc reads live offers from the production
-- discount-scraper API, so these may no longer exist there.
INSERT INTO list_items (id, list_id, name, quantity, category, is_completed, offer, created_at) VALUES
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Halfvolle melk 1L', '2', 'Zuivel', false,
   jsonb_build_object('product_id', 1, 'supermarket_key', 'dirk', 'supermarket_name', 'Dirk', 'price', 0.79,
                      'original_price', 1.09, 'special_discount', null, 'expire_date', to_char((now() + interval '3 days') AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')),
   now() - interval '6 days'),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'Volkoren brood', '1', 'Bakkerij', false, null, now() - interval '6 days'),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Bananen', '1 tros', 'Groente en fruit', true, null, now() - interval '5 days'),
  ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'Koffiebonen', null, 'Koffie en thee', false, null, now() - interval '2 days'),
  ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Kaas jong belegen', '500 g', 'Zuivel', false, null, now() - interval '2 hours'),
  ('20000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'Kipfilet 500g', '2', 'Vlees', false,
   jsonb_build_object('product_id', 4, 'supermarket_key', 'lidl', 'supermarket_name', 'Lidl', 'price', 3.99,
                      'original_price', 5.99, 'special_discount', null, 'expire_date', to_char((now() + interval '4 days') AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')),
   now() - interval '3 days'),
  ('20000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000002', 'Houtskool', '1 zak', null, false, null, now() - interval '3 days'),
  ('20000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000002', 'Cola Zero 1,5L', '4', 'Frisdrank', false, null, now() - interval '1 day'),
  ('20000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000003', 'Tandpasta', '2', null, false, null, now() - interval '10 days'),
  ('20000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000003', 'Shampoo', '1', null, true, null, now() - interval '10 days');

END
$demo$;
