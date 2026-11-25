import os
import sys
from pathlib import Path
from flask import Flask, render_template, request
from flask_wtf.csrf import CSRFProtect
from app.db import get_db, init_app

# Magic Values, this is where the magic happens
QUERY_DIR = Path(__file__).resolve().parent / "queries"

def _secret_from_env_file(path: Path) -> str | None:
    if not path.is_file():
        return None

    for line in path.read_text(encoding="utf-8").splitlines():
        name, separator, value = line.partition("=")
        if separator and name.strip() == "SECRET_KEY":
            return value.strip().strip("\"'") or None
    return None

def get_query(filename):
    return (QUERY_DIR / filename).read_text(encoding="utf-8").strip().rstrip(";")

def create_app():
    app = Flask(__name__, instance_relative_config=True)

    env_path = Path(app.root_path).parent / ".env"

    app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY") or _secret_from_env_file(env_path)
    app.config["DATABASE"] = str(Path(app.instance_path) / "pharma.sqlite")

    # Init the application and add a key for login
    CSRFProtect(app)
    init_app(app)

    # Routing happens from the functions below, this is where the magic is done
    @app.get("/")
    def index():
        return render_template("index.html", view=None)

    @app.get("/pharmacy")
    def pharmacy():
        q = request.args.get("q", "").strip()
        # Reservations and pending deliveries can overlap for the same order item.
        # Count the larger of the two, as the schema does, without joining batches
        # and order items together (which would multiply their quantities).
        pattern = "%" + q + "%"
        db = get_db()

        query = get_query("med_catalog.sql")
        medicines = db.execute(query, (pattern, pattern)).fetchall()

        return render_template(
            "pharmacy.html", view="pharmacy", medicines=medicines, query=q
        )

    @app.get("/warehouse")
    def warehouse():
        q = request.args.get("q", "").strip()
        # Reservations and pending deliveries can overlap for the same order item.
        # Count the larger of the two, as the schema does, without joining batches
        # and order items together (which would multiply their quantities).
        pattern = "%" + q + "%"
        db = get_db()
        query = get_query("med_catalog.sql")

        medicines = db.execute(query, (pattern, pattern)).fetchall()

        return render_template(
            "warehouse.html", view="warehouse", medicines=medicines, query=q
        )

    return app


if __name__ == "__main__":
    create_app().run(debug=True)
