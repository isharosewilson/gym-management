-- People who can log in (owner and front-desk staff)
CREATE TABLE IF NOT EXISTS users (
  id            SERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('owner', 'staff')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Gym members (they do not log in)
CREATE TABLE IF NOT EXISTS members (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  phone      TEXT NOT NULL,
  joined_on  DATE NOT NULL DEFAULT CURRENT_DATE,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_members_name  ON members (name);
CREATE INDEX IF NOT EXISTS idx_members_phone ON members (phone);

-- Plans the gym sells (Monthly, Yearly)
CREATE TABLE IF NOT EXISTS plans (
  id            SERIAL PRIMARY KEY,
  name          TEXT NOT NULL UNIQUE,
  duration_days INTEGER NOT NULL CHECK (duration_days > 0),
  price         INTEGER NOT NULL CHECK (price >= 0)
);

-- One row each time a member joins or renews
CREATE TABLE IF NOT EXISTS memberships (
  id          SERIAL PRIMARY KEY,
  member_id   INTEGER NOT NULL REFERENCES members (id) ON DELETE CASCADE,
  plan_id     INTEGER NOT NULL REFERENCES plans (id),
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  plan_price  INTEGER NOT NULL CHECK (plan_price >= 0),
  joining_fee INTEGER NOT NULL DEFAULT 0 CHECK (joining_fee >= 0),
  discount    INTEGER NOT NULL DEFAULT 0 CHECK (discount >= 0),
  amount      INTEGER GENERATED ALWAYS AS (plan_price + joining_fee - discount) STORED,
  created_by  INTEGER REFERENCES users (id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date),
  CHECK (discount <= plan_price + joining_fee)
);
CREATE INDEX IF NOT EXISTS idx_memberships_member_end ON memberships (member_id, end_date);

-- One payment per membership (the gym allows no part payments).
-- The receipt number is the payment's id.
CREATE TABLE IF NOT EXISTS payments (
  id            SERIAL PRIMARY KEY,
  membership_id INTEGER NOT NULL UNIQUE REFERENCES memberships (id) ON DELETE CASCADE,
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  method        TEXT NOT NULL CHECK (method IN ('cash', 'upi')),
  paid_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  received_by   INTEGER REFERENCES users (id)
);

-- One row per gym visit
CREATE TABLE IF NOT EXISTS attendance (
  id            SERIAL PRIMARY KEY,
  member_id     INTEGER NOT NULL REFERENCES members (id) ON DELETE CASCADE,
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  marked_by     INTEGER REFERENCES users (id)
);
CREATE INDEX IF NOT EXISTS idx_attendance_member_time ON attendance (member_id, checked_in_at);