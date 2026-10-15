const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

async function run() {
  const { DATABASE_URL, OWNER_NAME, OWNER_EMAIL, OWNER_PASSWORD } = process.env;

  if (!OWNER_EMAIL || !OWNER_PASSWORD) {
    console.error('Add OWNER_EMAIL and OWNER_PASSWORD to backend/.env first.');
    process.exit(1);
  }

  const pool = new Pool({ connectionString: DATABASE_URL });
  try {
    await pool.query(
      `INSERT INTO plans (name, duration_days, price)
       VALUES ('Monthly', 30, 1000), ('Yearly', 365, 10000)
       ON CONFLICT (name) DO NOTHING`
    );

    const hash = await bcrypt.hash(OWNER_PASSWORD, 10);
    await pool.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, 'owner')
       ON CONFLICT (email) DO NOTHING`,
      [OWNER_NAME || 'Owner', OWNER_EMAIL.toLowerCase(), hash]
    );

    console.log('Seed done: plans and owner account created.');
  } catch (err) {
    console.error('Seed failed:', err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

run();