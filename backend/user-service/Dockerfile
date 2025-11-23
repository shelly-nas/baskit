# Use Node.js LTS Alpine
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy shared utilities first
COPY shared/ /app/shared/

# Copy package files
COPY user-service/package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy application code
COPY user-service/ .

# Expose port
EXPOSE 3001

# Start application
CMD ["npm", "start"]
