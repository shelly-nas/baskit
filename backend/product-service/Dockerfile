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

# Copy product-service package files
WORKDIR /app
COPY product-service/package*.json ./

# Install product-service dependencies
RUN npm ci --omit=dev

# Copy application code
COPY product-service/ .

# Expose port
EXPOSE 3002

# Start application
CMD ["npm", "start"]
