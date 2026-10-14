# Database image with the schema baked in: the deploy copies only the compose
# file to the NAS, so a bind mount to ./database would not exist there.
# init.sql runs on the first start of an empty data volume. seed-demo.sql is
# deliberately not copied: demo data only goes to local dev and acc.
FROM postgres:16-alpine

COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
