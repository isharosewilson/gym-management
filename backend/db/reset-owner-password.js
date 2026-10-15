const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

async function run() {
  const { DATABASE_URL, OWNER_EMAIL, OWNER_PASSWORD } = process.env;

  if (!OWNER_EMAIL || !OWNER_PASSWORD) {
    console.error('Set OWNER_EMAIL and OWNER_PASSWORD in backend/.env first.');
    process.exit(1);
  }

  const pool = new Pool({ connectionString: DATABASE_URL });
  try {
    const hash = await bcrypt.hash(OWNER_PASSWORD, 10);
    const result = await pool.query(
      `UPDATE users SET password_hash = $1
       WHERE email = $2 AND role = 'owner'`,
      [hash, OWNER_EMAIL.toLowerCase()]
    );

    if (result.rowCount === 0) {
      console.log('No owner found with that email. Check OWNER_EMAIL in .env.');
    } else {
      console.log('Owner password updated.');
    }
  } catch (err) {
    console.error('Failed:', err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

run();
