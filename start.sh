#!/bin/sh
set -eu

cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
    echo 'Virtual environment missing. Create one with `python -m venv .venv && source .venv/bin/activate`' >&2
    exit 1
fi

flask --app app.app --debug run
