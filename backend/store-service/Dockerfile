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

# Copy store-service package files
WORKDIR /app
COPY store-service/package*.json ./

# Install store-service dependencies
RUN npm ci --omit=dev

# Copy application code
COPY store-service/ .

# Expose port
EXPOSE 3005

# Start application
CMD ["npm", "start"]
