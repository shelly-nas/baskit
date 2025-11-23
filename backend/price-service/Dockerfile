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

# Copy price-service package files
WORKDIR /app
COPY price-service/package*.json ./

# Install price-service dependencies
RUN npm ci --omit=dev

# Copy application code
COPY price-service/ .

# Expose port
EXPOSE 3004

# Start application
CMD ["npm", "start"]
