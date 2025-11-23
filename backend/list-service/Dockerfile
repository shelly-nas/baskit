# Use Node.js LTS Alpine
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy shared utilities first
COPY shared/ /app/shared/

# Copy package files
COPY list-service/package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy application code
COPY list-service/ .

# Expose port
EXPOSE 3003

# Start application
CMD ["npm", "start"]
