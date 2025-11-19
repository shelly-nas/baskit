#!/usr/bin/env node

/**
 * Database Migration Runner
 * Manages PostgreSQL schema migrations for Baskit
 */

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

// Database configuration
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'baskit',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const MIGRATIONS_DIR = path.join(__dirname, 'migrations');
const SCHEMA_DIR = path.join(__dirname, 'schema');

/**
 * Ensure migrations table exists
 */
async function ensureMigrationsTable() {
  const client = await pool.connect();
  try {
    const migrationTableSQL = fs.readFileSync(
      path.join(SCHEMA_DIR, '00_migrations.sql'),
      'utf8'
    );
    await client.query(migrationTableSQL);
    console.log('✓ Migrations table ready');
  } finally {
    client.release();
  }
}

/**
 * Get list of executed migrations
 */
async function getExecutedMigrations() {
  const client = await pool.connect();
  try {
    const result = await client.query(
      'SELECT version FROM schema_migrations ORDER BY version'
    );
    return result.rows.map(row => row.version);
  } finally {
    client.release();
  }
}

/**
 * Get list of pending migrations
 */
async function getPendingMigrations() {
  const executedMigrations = await getExecutedMigrations();
  const allMigrations = fs
    .readdirSync(SCHEMA_DIR)
    .filter(file => file.endsWith('.sql') && file !== '00_migrations.sql')
    .sort();

  return allMigrations.filter(
    migration => !executedMigrations.includes(migration)
  );
}

/**
 * Execute a single migration
 */
async function executeMigration(migrationFile) {
  const client = await pool.connect();
  const startTime = Date.now();
  
  try {
    await client.query('BEGIN');

    const migrationSQL = fs.readFileSync(
      path.join(SCHEMA_DIR, migrationFile),
      'utf8'
    );
    
    await client.query(migrationSQL);
    
    const executionTime = Date.now() - startTime;
    await client.query(
      `INSERT INTO schema_migrations (version, name, execution_time, success) 
       VALUES ($1, $2, $3, true)`,
      [migrationFile, migrationFile.replace('.sql', ''), executionTime]
    );

    await client.query('COMMIT');
    console.log(`✓ Executed: ${migrationFile} (${executionTime}ms)`);
    return true;
  } catch (error) {
    await client.query('ROLLBACK');
    
    // Record failed migration
    await client.query(
      `INSERT INTO schema_migrations (version, name, success, error_message) 
       VALUES ($1, $2, false, $3)`,
      [migrationFile, migrationFile.replace('.sql', ''), error.message]
    );
    
    console.error(`✗ Failed: ${migrationFile}`);
    console.error(`  Error: ${error.message}`);
    return false;
  } finally {
    client.release();
  }
}

/**
 * Run all pending migrations
 */
async function runMigrations() {
  console.log('🚀 Starting database migrations...\n');

  await ensureMigrationsTable();
  const pendingMigrations = await getPendingMigrations();

  if (pendingMigrations.length === 0) {
    console.log('✓ Database is up to date. No migrations needed.\n');
    return true;
  }

  console.log(`Found ${pendingMigrations.length} pending migration(s):\n`);
  pendingMigrations.forEach(m => console.log(`  - ${m}`));
  console.log('');

  for (const migration of pendingMigrations) {
    const success = await executeMigration(migration);
    if (!success) {
      console.error('\n✗ Migration failed. Stopping.\n');
      return false;
    }
  }

  console.log('\n✓ All migrations completed successfully!\n');
  return true;
}

/**
 * Show migration status
 */
async function showStatus() {
  await ensureMigrationsTable();
  
  const executedMigrations = await getExecutedMigrations();
  const pendingMigrations = await getPendingMigrations();

  console.log('\n📊 Database Migration Status\n');
  console.log(`Executed migrations: ${executedMigrations.length}`);
  executedMigrations.forEach(m => console.log(`  ✓ ${m}`));
  
  console.log(`\nPending migrations: ${pendingMigrations.length}`);
  if (pendingMigrations.length > 0) {
    pendingMigrations.forEach(m => console.log(`  ⏳ ${m}`));
  } else {
    console.log('  None - database is up to date');
  }
  console.log('');
}

/**
 * Initialize fresh database
 */
async function initDatabase() {
  console.log('🏗️  Initializing fresh database...\n');
  
  const client = await pool.connect();
  try {
    // Run init script
    const initSQL = fs.readFileSync(path.join(__dirname, 'init.sql'), 'utf8');
    await client.query(initSQL);
    console.log('✓ Database extensions and functions created\n');
    
    // Run all migrations
    await runMigrations();
  } catch (error) {
    console.error('✗ Database initialization failed:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

// CLI Commands
const command = process.argv[2];

(async () => {
  try {
    switch (command) {
      case 'migrate':
      case 'up':
        await runMigrations();
        break;
      case 'status':
        await showStatus();
        break;
      case 'init':
        await initDatabase();
        break;
      default:
        console.log(`
Baskit Database Migration Tool

Usage:
  node migrate.js <command>

Commands:
  migrate, up    Run pending migrations
  status         Show migration status
  init           Initialize fresh database with all migrations

Environment Variables:
  DB_HOST        Database host (default: localhost)
  DB_PORT        Database port (default: 5432)
  DB_NAME        Database name (default: baskit)
  DB_USER        Database user (default: postgres)
  DB_PASSWORD    Database password (default: postgres)
        `);
    }
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
})();
