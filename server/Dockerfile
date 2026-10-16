FROM node:22-alpine AS build
WORKDIR /server
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci
COPY src ./src
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine
WORKDIR /server
ENV NODE_ENV=production
COPY --from=build /server/node_modules ./node_modules
COPY --from=build /server/dist ./dist
COPY package.json ./
# Migrations are read at runtime (applied on startup), not compiled.
COPY migrations ./migrations
USER node
EXPOSE 3000
CMD ["node", "dist/index.js"]
