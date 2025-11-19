# Baskit Backend

Node.js and Express microservices backend for the Baskit grocery shopping application.

## Architecture

Baskit follows a **microservices architecture** with the following services:

- **User Service** (Port 3001) - Authentication, user management, preferences
- **Product Service** (Port 3002) - Product catalog, search, AI matching
- **List Service** (Port 3003) - Shopping lists, real-time sync via WebSocket
- **Price Service** (Port 3004) - Price aggregation, history, promotions
- **Store Service** (Port 3005) - Store locations, layouts, hours
- **Route Service** (Port 3006) - Route optimization (cheapest vs fastest)
- **Notification Service** (Port 3007) - Push notifications, emails

## Technology Stack

- **Runtime:** Node.js 18+ with Express.js
- **Database:** PostgreSQL 15+ (see `/database` directory)
- **Caching/Messaging:** Redis 7+
- **Real-time:** Socket.IO (List Service)
- **Security:** Helmet, CORS, JWT authentication
- **Logging:** Winston with structured logging
- **Validation:** Joi schemas
- **Containerization:** Docker & Docker Compose

## Project Structure

```
backend/
├── shared/                    # Shared utilities across services
│   └── src/
│       ├── database.js        # PostgreSQL connection pool
│       ├── logger.js          # Winston logger configuration
│       ├── errors.js          # Custom error classes
│       ├── middleware.js      # Shared middleware
│       └── index.js           # Exports
│
├── user-service/              # User authentication & management
│   ├── src/
│   │   ├── controllers/       # Business logic
│   │   ├── routes/            # API routes
│   │   └── index.js           # Service entry point
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
│
├── product-service/           # Product catalog & search
├── list-service/              # Shopping list management
├── price-service/             # Price tracking & promotions
├── store-service/             # Store information
├── route-service/             # Route optimization
└── notification-service/      # Notifications
```

## Getting Started

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15+ (or use Docker)
- Redis 7+ (or use Docker)

### Installation

1. **Clone the repository:**

```bash
cd backend
```

2. **Install dependencies for shared utilities:**

```bash
cd shared
npm install
cd ..
```

3. **Set up environment variables for each service:**

```bash
# User Service
cp user-service/.env.example user-service/.env

# Product Service
cp product-service/.env.example product-service/.env

# Repeat for other services...
```

4. **Initialize the database:**

```bash
cd ../database
npm install
node migrate.js init
node seed.js
cd ../backend
```

### Running with Docker Compose (Recommended)

Start all services with Docker Compose:

```bash
docker-compose up -d
```

View logs:

```bash
docker-compose logs -f
```

Stop services:

```bash
docker-compose down
```

### Running Services Individually (Development)

For local development without Docker:

```bash
# Terminal 1 - User Service
cd user-service
npm install
npm run dev

# Terminal 2 - Product Service
cd product-service
npm install
npm run dev

# Terminal 3 - List Service
cd list-service
npm install
npm run dev
```

## Health Endpoints

Each service provides health check endpoints:

- `GET /api/health` - Comprehensive health status
- `GET /api/health/ready` - Readiness probe (Kubernetes)
- `GET /api/health/live` - Liveness probe (Kubernetes)

### Examples

```bash
# User Service health check
curl http://localhost:3001/api/health

# Product Service health check
curl http://localhost:3002/api/health

# List Service health check (includes WebSocket status)
curl http://localhost:3003/api/health
```

### Response Format

```json
{
  "service": "user-service",
  "status": "ok",
  "timestamp": "2025-11-19T10:30:00.000Z",
  "uptime": 3600.5,
  "environment": "development",
  "database": "connected"
}
```

## API Documentation

### User Service (Port 3001)

**Authentication:**
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get JWT token
- `POST /api/auth/logout` - Logout user
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password with token

**User Management:**
- `GET /api/users/profile` - Get user profile (requires auth)
- `PUT /api/users/profile` - Update user profile (requires auth)
- `GET /api/users/preferences` - Get user preferences (requires auth)
- `PUT /api/users/preferences` - Update preferences (requires auth)
- `DELETE /api/users/account` - Delete account (requires auth)

### Product Service (Port 3002)

- `GET /api/products` - List products
- `GET /api/products/search?q=milk` - Search products
- `GET /api/products/:id` - Get product details

### List Service (Port 3003)

- `GET /api/lists` - Get user's lists (requires auth)
- `POST /api/lists` - Create new list (requires auth)
- `GET /api/lists/:id` - Get list details (requires auth)
- `PUT /api/lists/:id` - Update list (requires auth)
- `DELETE /api/lists/:id` - Delete list (requires auth)
- `POST /api/lists/:id/items` - Add item to list (requires auth)
- `POST /api/lists/:id/share` - Share list (requires auth)

**WebSocket Events:**
- `join-list` - Join a list room for real-time updates
- `leave-list` - Leave a list room
- `list-updated` - Receive real-time list updates

## Shared Utilities

The `shared` directory contains utilities used across all microservices:

### Database (`database.js`)

```javascript
const { database } = require('../../shared/src');

// Connect to database
await database.connect();

// Execute query
const result = await database.query('SELECT * FROM users WHERE id = $1', [userId]);

// Health check
const healthy = await database.healthCheck();
```

### Logger (`logger.js`)

```javascript
const { logger } = require('../../shared/src');

logger.info('User logged in', { userId, email });
logger.error('Database error', { error });
logger.debug('Query executed', { query, duration });
```

### Error Handling (`errors.js`)

```javascript
const { NotFoundError, ValidationError } = require('../../shared/src');

throw new NotFoundError('User not found');
throw new ValidationError('Invalid email format');
```

### Middleware (`middleware.js`)

```javascript
const { authenticate, asyncHandler, validate } = require('../../shared/src');

router.get('/profile', authenticate, asyncHandler(async (req, res) => {
  // Handler code
}));
```

## Development

### Adding a New Service

1. Create service directory: `mkdir backend/new-service`
2. Copy package.json from existing service
3. Create `src/index.js` with Express setup
4. Create health routes: `src/routes/health.routes.js`
5. Add service to `docker-compose.yml`
6. Update this README

### Code Style

- Use async/await for asynchronous operations
- Wrap route handlers with `asyncHandler`
- Use Winston logger, not `console.log`
- Validate request bodies with Joi schemas
- Follow RESTful API conventions

### Error Handling

All errors are handled centrally by the `errorHandler` middleware:

```javascript
throw new NotFoundError('Resource not found'); // 404
throw new ValidationError('Invalid input'); // 400
throw new UnauthorizedError(); // 401
throw new ForbiddenError(); // 403
```

## Testing

```bash
# Run tests for a specific service
cd user-service
npm test

# Run all tests
npm run test:all
```

## Deployment

### Production Build

```bash
# Build Docker images
docker-compose -f docker-compose.prod.yml build

# Start production services
docker-compose -f docker-compose.prod.yml up -d
```

### Environment Variables

Ensure all services have proper production environment variables:

- Set `NODE_ENV=production`
- Use strong JWT secrets
- Configure proper CORS origins
- Set database connection pooling limits
- Enable SSL/TLS for PostgreSQL

## Monitoring

- **Logs:** Winston logs to `logs/combined.log` and `logs/error.log`
- **Health Checks:** All services expose `/api/health` endpoints
- **Metrics:** Ready for Prometheus integration

## Security

- Helmet.js for HTTP security headers
- CORS configuration per service
- JWT authentication for protected routes
- Input validation with Joi
- Password hashing with bcrypt
- SQL injection prevention with parameterized queries

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

ISC

## Support

For issues or questions, refer to the main project documentation.
