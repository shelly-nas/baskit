# Baskit web app: build the Flutter web bundle, serve it with nginx.

# ---- Build ----
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Relative URLs: nginx proxies /api/discounts to the discount-scraper public
# API and /api to the Baskit server.
ARG DISCOUNT_API_URL=/api/discounts
ARG BASKIT_API_URL=/api
RUN flutter build web --release \
      --no-web-resources-cdn \
      --dart-define=DISCOUNT_API_URL=${DISCOUNT_API_URL} \
      --dart-define=BASKIT_API_URL=${BASKIT_API_URL}

# ---- Serve ----
FROM nginx:1.27-alpine

# Upstreams (overridable at runtime): the discount-scraper API and the Baskit server.
ENV DISCOUNT_API_UPSTREAM=http://discount-scraper-api:3001
ENV BASKIT_API_UPSTREAM=http://server:3000

COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
