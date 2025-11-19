# Baskit Database

PostgreSQL database schema and migration system for the Baskit grocery shopping application.

## Structure

```
database/
├── init.sql              # Database initialization (extensions, functions)
├── migrate.js            # Migration runner script
├── seed.js               # Seed data runner script
├── schema/               # SQL schema files
│   ├── 00_migrations.sql         # Migration tracking table
│   ├── 01_user_service.sql       # User accounts and preferences
│   ├── 02_product_service.sql    # Products, categories, variations
│   ├── 03_list_service.sql       # Shopping lists and items
│   ├── 04_store_service.sql      # Store locations and layouts
│   ├── 05_price_service.sql      # Prices, history, and promotions
│   └── 06_supporting_tables.sql  # Favorites, savings, notifications
├── migrations/           # Version-controlled migrations (future)
└── seeds/                # Initial test data
    └── 01_initial_data.sql       # Categories, stores, test users
```

## Requirements

- PostgreSQL 15+
- Node.js 16+
- npm package: `pg`

## Installation

1. Install PostgreSQL dependencies:

```bash
npm install pg
```

2. Set environment variables (optional):

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=baskit
export DB_USER=postgres
export DB_PASSWORD=postgres
```

## Usage

### Initialize Fresh Database

Run all setup scripts including extensions, functions, and schema:

```bash
node migrate.js init
```

### Run Migrations

Execute pending schema migrations:

```bash
node migrate.js migrate
# or
node migrate.js up
```

### Check Migration Status

View executed and pending migrations:

```bash
node migrate.js status
```

### Load Seed Data

Populate database with initial test data:

```bash
node seed.js
```

## Database Schema

### Core Services

**User Service** (`01_user_service.sql`)

- `users` - User accounts with authentication
- `user_preferences` - User settings and preferences

**Product Service** (`02_product_service.sql`)

- `categories` - Hierarchical product categories
- `products` - Product catalog
- `product_variations` - Product sizes and packages

**List Service** (`03_list_service.sql`)

- `lists` - Shopping lists (private and shared)
- `list_items` - Items in shopping lists
- `list_sharing` - Collaborative list permissions
- `list_versions` - Version history for conflict resolution

**Store Service** (`04_store_service.sql`)

- `stores` - Physical store locations
- `store_layouts` - Category placement for navigation

**Price Service** (`05_price_service.sql`)

- `prices` - Current product prices
- `price_history` - Historical price tracking
- `promotions` - Store promotions and discounts

**Supporting Tables** (`06_supporting_tables.sql`)

- `favorites` - User favorite products with price alerts
- `savings_tracking` - Historical savings analytics
- `notifications` - User notifications
- `shopping_routes` - Optimized shopping routes

### Key Features

- **UUID Primary Keys**: All tables use UUIDs for global uniqueness
- **Timestamps**: Automatic `created_at` and `updated_at` tracking
- **JSONB Support**: Flexible data storage for complex structures
- **Full-Text Search**: GIN indexes for product name search
- **Geospatial**: Location-based store queries
- **Soft Deletes**: Cascading deletes with referential integrity

## Docker Compose Setup

Example `docker-compose.yml` for local development:

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:15-alpine
    container_name: baskit-db
    environment:
      POSTGRES_DB: baskit
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/01-init.sql

volumes:
  postgres_data:
```

## Migration Strategy

### Current Approach (Initial Development)

Schema files in `schema/` directory are executed sequentially by version number (e.g., `01_`, `02_`, etc.).

### Future Approach (Production)

Version-controlled migrations in `migrations/` directory with timestamps:

- Format: `YYYYMMDD_HHmmss_description.sql`
- Example: `20251118_143000_add_user_avatars.sql`

## Seed Data

Initial test data includes:

- **10 product categories** (Fruits, Dairy, Meat, etc.)
- **8 store locations** across Amsterdam and Rotterdam
- **2 test user accounts** (free and premium tiers)
- **Sample products** with variations and prices

### Test Users

- **Free User**: `test.user@baskit.nl` / `password123`
- **Premium User**: `premium.user@baskit.nl` / `password123`

⚠️ **Note**: These are development passwords. Never use in production.

## Best Practices

1. **Always use transactions** for multi-statement operations
2. **Create indexes** for foreign keys and frequently queried columns
3. **Use JSONB** for flexible, structured data (preferences, metadata)
4. **Enable extensions** at database level (uuid-ossp, pgcrypto)
5. **Test migrations** in development before production deployment
6. **Backup before migrations** in production environments

## Troubleshooting

### Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -U postgres -d baskit

# Check if PostgreSQL is running
pg_isready -h localhost -p 5432
```

### Permission Errors

```sql
-- Grant privileges to user
GRANT ALL PRIVILEGES ON DATABASE baskit TO your_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO your_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO your_user;
```

### Reset Database

```bash
# Drop and recreate database
dropdb baskit
createdb baskit
node migrate.js init
node seed.js
```

## Support

For issues or questions, refer to the main project documentation or contact the development team.
