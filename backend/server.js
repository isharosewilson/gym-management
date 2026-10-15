require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const pool = require('./db');
const authRoutes = require('./routes/auth');

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET is missing in backend/.env');
  process.exit(1);
}

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ status: 'error', db: 'down' });
  }
});

app.use('/api/auth', authRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, (err) => {
  if (err) {
    console.error('Could not start:', err.message);
    process.exit(1);
  }
  console.log('Server running on http://localhost:' + PORT);
});