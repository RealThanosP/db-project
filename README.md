# Pharmacy warehouse app

## Quickstart

Run once from the project root:

```sh
python bootstrap.py
```

This creates `.venv` if needed, installs `requirements.txt`, copies `.env.example`
to a local `.env` with a generated `SECRET_KEY`, initializes
`instance/pharma.sqlite` from `schema.sql`, and runs the tests. Re-running it
keeps the existing secret and database.

Start the development server by running:

```sh
./start.sh
```

or

```sh
flask --app app.app --debug run
```

Open <http://127.0.0.1:5000/> to choose a preview, or go directly to <http://127.0.0.1:5000/pharmacy> or <http://127.0.0.1:5000/warehouse>. If you make changes, and manage to not crash the backend, you can see the changes live in your browser.

The app reads the secret from `.env`, or from the `SECRET_KEY` environment variable when one is set. Keep `.env` and `instance/` local. The home page links to pharmacy and warehouse views. The pharmacy catalog reads from SQLite; the warehouse view still uses sample data. Authentication and order and warehouse operations are still to be built.

## Sample database data

After setup, add fictional pharmacies, users, medicines, batches and orders with:

```sh
.venv/bin/python scripts/seed_db.py
```

The script adds records without deleting existing data. Run it again to add another set. All generated users have the password `demo-password`, stored as a hash. Use `--database /path/to/database.sqlite` for another existing database and `--seed 42` to repeat generated values.
