CREATE TABLE providers (
  provider_id INTEGER PRIMARY KEY,
  full_name TEXT NOT NULL,
  provider_type TEXT NOT NULL
);

CREATE TABLE offers (
  offer_id INTEGER PRIMARY KEY,
  post_id INTEGER NOT NULL,
  provider_id INTEGER NOT NULL REFERENCES providers(provider_id),
  amount NUMERIC(10, 2) NOT NULL,
  status TEXT NOT NULL
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

INSERT INTO providers VALUES
  (201, 'Green Cycle Collectors', 'collector'),
  (202, 'Oroquieta Junk Shop', 'junk_shop');

INSERT INTO offers VALUES
  (7001, 9001, 201, 135.00, 'pending'),
  (7002, 9002, 202, 275.00, 'accepted');

INSERT INTO materials VALUES
  ('Plastic', true),
  ('Metal', true),
  ('Glass', true),
  ('Residual', false);

