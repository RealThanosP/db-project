import sqlite3
from pathlib import Path


def initialize_database(database: Path, schema: Path) -> bool:
    """Create the database once; leave an existing database untouched."""
    if database.exists():
        return False

    database.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(database)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(schema.read_text(encoding="utf-8"))
        violations = connection.execute("PRAGMA foreign_key_check").fetchall()
        if violations:
            raise RuntimeError(f"Schema has foreign key violations: {violations}")
        connection.commit()
    except Exception:
        connection.close()
        database.unlink(missing_ok=True)
        raise
    connection.close()
    return True


def get_db():
    from flask import current_app, g
    if "db" not in g:
        g.db = sqlite3.connect(current_app.config["DATABASE"])
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


def close_db(error=None):
    from flask import g

    connection = g.pop("db", None)
    if connection is not None:
        connection.close()


def init_app(app):
    app.teardown_appcontext(close_db)
