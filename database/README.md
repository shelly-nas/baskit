# Baskit Database

PostgreSQL database schema and migration system for the Baskit grocery shopping application.

## Structure

```
database/
├── init.sql              # Complete database schema (extensions, functions, tables)
├── package.json          # Project metadata
└── seeds/                # Initial test data
    └── 01_initial_data.sql       # Default test users
```

## Requirements

- Docker & Docker Compose (recommended)
- PostgreSQL 15+ (for manual setup)

## Usage

### Docker Setup (Recommended)

The database is automatically initialized when the PostgreSQL container starts:

```bash
docker-compose up -d postgres
```

This automatically:

- Creates the database with extensions
- Runs the schema initialization (`init.sql`)
- Loads seed data with test users (`seeds/01_initial_data.sql`)

To rebuild the database from scratch:

```bash
docker-compose down -v  # Remove volumes
docker-compose up -d postgres  # Recreate with fresh data
```

### Manual Setup (Alternative)

If running PostgreSQL outside Docker:

```bash
# Create database
createdb baskit

# Run initialization script
psql -h localhost -U postgres -d baskit -f database/init.sql

# Load seed data (optional)
psql -h localhost -U postgres -d baskit -f database/seeds/01_initial_data.sql
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
      - ./database/seeds/01_initial_data.sql:/docker-entrypoint-initdb.d/02-seed.sql

volumes:
  postgres_data:
```

The PostgreSQL container automatically executes SQL files in `/docker-entrypoint-initdb.d/` in alphabetical order on first startup:

1. `01-init.sql` - Complete database schema (extensions, functions, all tables)
2. `02-seed.sql` - Test users and initial data

## Seed Data

Initial test data includes:

- **3 test user accounts** (free tier, premium tier, and unverified)
- User preferences for each test account
- Future: Product categories, store locations, sample products with prices

### Test Users

All test users share the same password for convenience:

- **Free User (Verified)**: `test@baskit.app` / `TestPassword123!`
- **Premium User (Verified)**: `premium@baskit.app` / `TestPassword123!`
- **Unverified User**: `unverified@baskit.app` / `TestPassword123!`

⚠️ **Note**: These are development accounts with development passwords. Never use in production.

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

**With Docker (Recommended):**

```bash
docker-compose down -v  # Remove volumes
docker-compose up -d postgres  # Recreate with fresh data
```

**Manual PostgreSQL:**

```bash
# Drop and recreate database
dropdb baskit
createdb baskit

# Initialize schema and seed data
psql -h localhost -U postgres -d baskit -f init.sql
psql -h localhost -U postgres -d baskit -f seeds/01_initial_data.sql
```

## Support

For issues or questions, refer to the main project documentation or contact the development team.
