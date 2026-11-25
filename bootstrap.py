"""Set up the local Python environment, secret key, and SQLite database."""

import re
import secrets
import subprocess
import sys
import venv
from pathlib import Path

from app.db import initialize_database


ROOT = Path(__file__).resolve().parent


def ensure_env_file() -> None:
    example = ROOT / ".env.example"
    destination = ROOT / ".env"
    exists = destination.exists()
    contents = (
        destination.read_text(encoding="utf-8")
        if exists
        else example.read_text(encoding="utf-8")
    )
    matches = list(re.finditer(r"(?m)^SECRET_KEY[ \t]*=[ \t]*(.*)$", contents))
    if len(matches) != 1:
        raise RuntimeError(
            "Expected exactly one SECRET_KEY entry in .env or .env.example"
        )

    if not matches[0].group(1).strip():
        contents = (
            contents[: matches[0].start(1)]
            + secrets.token_hex(32)
            + contents[matches[0].end(1) :]
        )
        destination.write_text(contents, encoding="utf-8")
        destination.chmod(0o600)
        print("Created local SECRET_KEY in .env")
    elif not exists:
        contents = (
            contents[: matches[0].start(1)]
            + secrets.token_hex(32)
            + contents[matches[0].end(1) :]
        )
        destination.write_text(contents, encoding="utf-8")
        destination.chmod(0o600)
        print("Created .env from .env.example")
    else:
        print("Keeping existing .env and SECRET_KEY")


def ensure_venv() -> Path:
    interpreter = ROOT / ".venv" / "bin" / "python"
    if not interpreter.exists():
        print("Creating .venv", flush=True)
        venv.create(ROOT / ".venv", with_pip=True)
    return interpreter


def main() -> None:
    ensure_env_file()
    interpreter = ensure_venv()
    print("Installing dependencies", flush=True)
    subprocess.run(
        [
            str(interpreter),
            "-m",
            "pip",
            "install",
            "-r",
            str(ROOT / "requirements.txt"),
        ],
        check=True,
        cwd=ROOT,
    )

    database = ROOT / "instance" / "pharma.sqlite"
    created = initialize_database(database, ROOT / "schema.sql")
    print(
        "Created instance/pharma.sqlite"
        if created
        else "Keeping existing instance/pharma.sqlite"
    )

    print("Ready: .venv/bin/python -m flask --app app.app run --debug")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Bootstrap failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
