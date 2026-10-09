# Migrations

`database/init.sql` creates the schema on a fresh database. Every schema change
after that is a new file here, named `NNN_description.sql` with a unique
three digit number. The server applies pending files in order on startup and
records them in `schema_migrations`; each file runs in its own transaction.

Also apply the change to `database/init.sql`? No: init.sql stays the schema of
the first release, migrations bring every database (new or old) up to date.
Write migrations so they also work on a fresh database created from init.sql.
