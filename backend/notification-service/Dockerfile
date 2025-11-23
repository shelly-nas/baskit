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

# Copy notification-service package files
WORKDIR /app
COPY notification-service/package*.json ./

# Install notification-service dependencies
RUN npm ci --omit=dev

# Copy application code
COPY notification-service/ .

# Expose port
EXPOSE 3007

# Start application
CMD ["npm", "start"]
