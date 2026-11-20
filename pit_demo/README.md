# RecyConnect PIT distributed database demonstrator

This is a separate demonstrator for the IT315 PIT. It does not replace the
Flutter/Firebase application.

## What it demonstrates

- Horizontal fragmentation: household profiles and pickup posts are stored on
  `households-db`; collectors, junk shops, and offers are stored on
  `providers-db`.
- Replication: the `materials` reference table is seeded identically on both
  nodes.
- Distributed query processing: `client/main.py` reads both fragments and
  joins posts with offers at the coordinator.
- Distributed transaction management: the coordinator runs a successful
  two-phase commit and then simulates a node failure before the second prepare,
  rolling the first prepared transaction back.

## Run the demonstration

From this directory:

```powershell
docker compose up --abort-on-container-exit --build
docker compose down -v
```

The output should include:

```text
replicas_match: True
2PC SUCCESS: both fragments prepared and committed
2PC ROLLBACK: simulated provider-node failure before prepare
```

## 20-minute defense flow

1. Explain that the Flutter app is the client-facing recycling system and this
   folder is the PIT distributed-database demonstrator.
2. Show the two PostgreSQL containers in Docker Compose.
3. Show the household fragment on `households-db` and provider fragment on
   `providers-db`.
4. Run the distributed query and explain the coordinator-side join.
5. Show that the replicated `materials` rows match on both nodes.
6. Run the successful 2PC path.
7. Run the simulated failure path and explain why no partial transaction is
   retained.

