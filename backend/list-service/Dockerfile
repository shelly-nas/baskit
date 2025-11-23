# Use Node.js LTS Alpine
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy shared utilities first
COPY shared/package*.json /app/shared/
COPY shared/src/ /app/shared/src/

# Install shared dependencies
WORKDIR /app/shared
RUN npm ci --omit=dev

# Copy list-service package files
WORKDIR /app
COPY list-service/package*.json ./

# Install list-service dependencies
RUN npm ci --omit=dev

# Copy application code
COPY list-service/ .

# Expose port
EXPOSE 3003

# Start application
CMD ["npm", "start"]
