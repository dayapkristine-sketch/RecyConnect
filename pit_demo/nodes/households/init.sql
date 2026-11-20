CREATE TABLE households (
  household_id INTEGER PRIMARY KEY,
  full_name TEXT NOT NULL,
  city TEXT NOT NULL
);

CREATE TABLE posts (
  post_id INTEGER PRIMARY KEY,
  household_id INTEGER NOT NULL REFERENCES households(household_id),
  material TEXT NOT NULL,
  status TEXT NOT NULL,
  estimated_price NUMERIC(10, 2) NOT NULL
);

-- Replicated reference fragment: the same rows exist on both nodes.
CREATE TABLE materials (
  material TEXT PRIMARY KEY,
  recyclable BOOLEAN NOT NULL
);

CREATE TABLE transaction_events (
  event_id TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO households VALUES
  (101, 'Ana Santos', 'Oroquieta City'),
  (102, 'Ben Cruz', 'Oroquieta City');

INSERT INTO posts VALUES
  (9001, 101, 'Plastic', 'posted', 120.00),
  (9002, 102, 'Metal', 'accepted', 250.00);

INSERT INTO materials VALUES
  ('Plastic', true),
  ('Metal', true),
  ('Glass', true),
  ('Residual', false);

