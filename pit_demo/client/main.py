import os
import uuid
from contextlib import closing

import psycopg2


PASSWORD = "pit_password"


def connect(host: str):
    return psycopg2.connect(
        host=host,
        port=5432,
        dbname="recyconnect",
        user="pit",
        password=PASSWORD,
    )


def distributed_query():
    """Fetch fragments from both nodes and join them at the coordinator."""
    with closing(connect("households-db")) as household_db, closing(
        connect("providers-db")
    ) as provider_db:
        with household_db.cursor() as cursor:
            cursor.execute(
                """
                SELECT p.post_id, h.full_name, p.material, p.status,
                       p.estimated_price
                FROM posts p
                JOIN households h ON h.household_id = p.household_id
                ORDER BY p.post_id
                """
            )
            posts = {row[0]: row for row in cursor.fetchall()}

        with provider_db.cursor() as cursor:
            cursor.execute(
                """
                SELECT o.post_id, pr.full_name, pr.provider_type,
                       o.amount, o.status
                FROM offers o
                JOIN providers pr ON pr.provider_id = o.provider_id
                ORDER BY o.post_id
                """
            )
            offers = cursor.fetchall()

        print("\nDISTRIBUTED QUERY: household posts + provider offers")
        for post_id, provider, provider_type, amount, offer_status in offers:
            post = posts[post_id]
            print(
                f"post={post_id} | household={post[1]} | material={post[2]} | "
                f"provider={provider} ({provider_type}) | offer={amount} | "
                f"post_status={post[3]} | offer_status={offer_status}"
            )


def replication_check():
    with closing(connect("households-db")) as left, closing(
        connect("providers-db")
    ) as right:
        with left.cursor() as left_cursor, right.cursor() as right_cursor:
            left_cursor.execute("SELECT material, recyclable FROM materials ORDER BY material")
            right_cursor.execute("SELECT material, recyclable FROM materials ORDER BY material")
            left_rows = left_cursor.fetchall()
            right_rows = right_cursor.fetchall()
        print("\nREPLICATION CHECK")
        print(f"households-db materials: {len(left_rows)} rows")
        print(f"providers-db materials:  {len(right_rows)} rows")
        print(f"replicas_match: {left_rows == right_rows}")


def two_phase_commit(simulate_failure: bool):
    """Demonstrate prepare/commit and prepare/failure/rollback paths."""
    event_id = str(uuid.uuid4())
    left = right = None
    try:
        left = connect("households-db")
        right = connect("providers-db")
        left.tpc_begin(left.xid(42, f"pit-left-{event_id}", ""))
        right.tpc_begin(right.xid(42, f"pit-right-{event_id}", ""))
        for database, label in ((left, "households fragment"), (right, "provider fragment")):
            with database.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO transaction_events(event_id, description) VALUES (%s, %s)",
                    (event_id, f"2PC event on {label}"),
                )

        left.tpc_prepare()
        if simulate_failure:
            raise RuntimeError("simulated provider-node failure before prepare")

        right.tpc_prepare()
        left.tpc_commit()
        right.tpc_commit()
        print("\n2PC SUCCESS: both fragments prepared and committed")
    except Exception as error:
        if left is not None:
            try:
                left.tpc_rollback()
            except psycopg2.Error:
                pass
        if right is not None:
            try:
                right.tpc_rollback()
            except psycopg2.Error:
                pass
        print(f"\n2PC ROLLBACK: {error}")
    finally:
        if left is not None:
            left.close()
        if right is not None:
            right.close()


if __name__ == "__main__":
    distributed_query()
    replication_check()
    two_phase_commit(simulate_failure=False)
    two_phase_commit(simulate_failure=True)

