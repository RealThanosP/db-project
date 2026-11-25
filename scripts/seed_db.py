"""Add fictional, linked records to an existing local database."""

import argparse
import random
import sqlite3
import sys
from datetime import date, timedelta
from pathlib import Path
from uuid import uuid4

from faker import Faker
from werkzeug.security import generate_password_hash

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = ROOT / "instance" / "pharma.sqlite"


def seed_database(database: Path, seed: int | None = None) -> None:
    if not database.is_file():
        raise FileNotFoundError(
            f"Database not found: {database}. Run bootstrap.py first."
        )

    fake = Faker()
    fake.seed_instance(seed)
    rng = random.Random(seed)
    password_hash = generate_password_hash("demo-password")
    today = date.today()

    # mode=rw prevents SQLite from silently creating a new, empty database.
    connection = sqlite3.connect(database.resolve().as_uri() + "?mode=rw", uri=True)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        with connection:
            medicines = []
            for index in range(20):
                barcode = rng.randrange(10**12, 10**13)
                while connection.execute(
                    'SELECT 1 FROM "Medicine" WHERE barcode = ?', (barcode,)
                ).fetchone():
                    barcode = rng.randrange(10**12, 10**13)
                name = f"{fake.company()} Sample {index + 1}"
                connection.execute(
                    'INSERT INTO "Medicine" VALUES (?, ?, ?, ?, ?)',
                    (
                        barcode,
                        name,
                        "tablets",
                        rng.choice([10, 20, 30]),
                        round(rng.uniform(2, 30), 2),
                    ),
                )
                for _ in range(2):
                    connection.execute(
                        'INSERT INTO "Batch" (med_id, exp_date, available_qty, number) VALUES (?, ?, ?, ?)',
                        (
                            barcode,
                            (today + timedelta(days=rng.randint(90, 900))).isoformat(),
                            rng.randint(50, 200),
                            rng.randint(10000, 99999),
                        ),
                    )
                medicines.append(barcode)

            warehouse_user = str(uuid4())
            connection.execute(
                'INSERT INTO "User" (id, name, password, employer_id) VALUES (?, ?, ?, NULL)',
                (warehouse_user, fake.name(), password_hash),
            )
            for _ in range(8):
                address_id, pharmacy_id, user_id = (str(uuid4()) for _ in range(3))
                connection.execute(
                    'INSERT INTO "Address" (id, city, street, st_number, floor) VALUES (?, ?, ?, ?, ?)',
                    (
                        address_id,
                        fake.city(),
                        fake.street_name(),
                        rng.randint(1, 150),
                        rng.randint(0, 4),
                    ),
                )
                connection.execute(
                    'INSERT INTO "Pharmacy" (id, VAT, email, name, address_id) VALUES (?, ?, ?, ?, ?)',
                    (
                        pharmacy_id,
                        rng.randint(100000000, 999999999),
                        fake.safe_email(),
                        f"{fake.last_name()} Pharmacy",
                        address_id,
                    ),
                )
                connection.execute(
                    'INSERT INTO "Phones" (phone, pharmacy_id) VALUES (?, ?)',
                    (rng.randint(2100000000, 2199999999), pharmacy_id),
                )
                connection.execute(
                    'INSERT INTO "User" (id, name, password, employer_id) VALUES (?, ?, ?, ?)',
                    (user_id, fake.name(), password_hash, pharmacy_id),
                )
                for order_number in range(2):
                    order_id = str(uuid4())
                    order_date = today - timedelta(days=rng.randint(1, 30))
                    connection.execute(
                        'INSERT INTO "Order" (id, exp_doa, submit_date, state, user_id, pharmacy_id) VALUES (?, ?, ?, ?, ?, ?)',
                        (
                            order_id,
                            (today + timedelta(days=rng.randint(1, 14))).isoformat(),
                            order_date.isoformat(),
                            "new" if order_number == 0 else "processing",
                            user_id if order_number == 0 else warehouse_user,
                            pharmacy_id,
                        ),
                    )
                    for item_index, barcode in enumerate(
                        rng.sample(medicines, 2), start=1
                    ):
                        quantity = rng.randint(2, 8)
                        connection.execute(
                            'INSERT INTO "Order_Items" (order_id, idx, wanted_qty, refused_qty, medicine_id) VALUES (?, ?, ?, 0, ?)',
                            (order_id, item_index, quantity, barcode),
                        )
                        if order_number == 1:
                            connection.execute(
                                'INSERT INTO "Commits" (order_id, order_item_idx, commited_qty) VALUES (?, ?, ?)',
                                (order_id, item_index, quantity),
                            )
                    if order_number == 1:
                        delivery_id = str(uuid4())
                        connection.execute(
                            'INSERT INTO "Delivery" (id, state, address_id, order_id) VALUES (?, ?, ?, ?)',
                            (delivery_id, "pending", address_id, order_id),
                        )
                        for item_index, quantity in connection.execute(
                            'SELECT idx, wanted_qty FROM "Order_Items" WHERE order_id = ?',
                            (order_id,),
                        ).fetchall():
                            connection.execute(
                                'INSERT INTO "Delivery_Items" (item_idx, delivery_id, quantity, order_id, order_item_idx) VALUES (?, ?, ?, ?, ?)',
                                (
                                    item_index,
                                    delivery_id,
                                    quantity,
                                    order_id,
                                    item_index,
                                ),
                            )

            violations = connection.execute(
                'SELECT reason FROM "Schema_Violations" LIMIT 1'
            ).fetchone()
            if violations:
                raise RuntimeError(f"Schema validation failed: {violations[0]}")
            if connection.execute("PRAGMA foreign_key_check").fetchone():
                raise RuntimeError("Foreign key validation failed")
    finally:
        connection.close()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--database",
        type=Path,
        default=DEFAULT_DATABASE,
        help="existing SQLite database (default: instance/pharma.sqlite)",
    )
    parser.add_argument("--seed", type=int, help="seed for generated values")
    args = parser.parse_args()
    try:
        seed_database(args.database, args.seed)
    except (OSError, sqlite3.Error, RuntimeError) as error:
        print(f"Could not seed database: {error}", file=sys.stderr)
        raise SystemExit(1) from error
    print(
        f"Added fake data to {args.database}: 20 medicines, 40 batches, 8 pharmacies, 9 users and 16 orders."
    )
    print("Demo users all use the password: demo-password")


if __name__ == "__main__":
    main()
