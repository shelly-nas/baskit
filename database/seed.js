#!/usr/bin/env node

/**
 * Database Seed Runner
 * Populates database with initial test data
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

const SEEDS_DIR = path.join(__dirname, 'seeds');

/**
 * Run all seed files
 */
async function runSeeds() {
  console.log('🌱 Starting database seeding...\n');

  const client = await pool.connect();
  
  try {
    const seedFiles = fs
      .readdirSync(SEEDS_DIR)
      .filter(file => file.endsWith('.sql'))
      .sort();

    if (seedFiles.length === 0) {
      console.log('No seed files found.\n');
      return;
    }

    console.log(`Found ${seedFiles.length} seed file(s):\n`);

    for (const seedFile of seedFiles) {
      console.log(`  Seeding: ${seedFile}`);
      
      const seedSQL = fs.readFileSync(
        path.join(SEEDS_DIR, seedFile),
        'utf8'
      );
      
      await client.query(seedSQL);
      console.log(`  ✓ Completed: ${seedFile}\n`);
    }

    console.log('✓ All seed data loaded successfully!\n');
  } catch (error) {
    console.error('✗ Seeding failed:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

// Run seeding
(async () => {
  try {
    await runSeeds();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
})();
