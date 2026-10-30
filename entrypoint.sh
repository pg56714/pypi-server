#!/bin/sh
# Generate a bcrypt htpasswd file from PYPI_USERNAME / PYPI_PASSWORD at startup,
# so no credentials are stored in the image or the repository.
set -eu

if [ -z "${PYPI_USERNAME:-}" ] || [ -z "${PYPI_PASSWORD:-}" ]; then
    echo "PYPI_USERNAME and PYPI_PASSWORD must be set (see .env.example)." >&2
    exit 1
fi

python - <<'PY'
import os

import bcrypt

user = os.environ["PYPI_USERNAME"]
password = os.environ["PYPI_PASSWORD"].encode()
if ":" in user:
    raise SystemExit("PYPI_USERNAME must not contain ':'")
if len(password) > 72:
    raise SystemExit("PYPI_PASSWORD must be at most 72 bytes (bcrypt limit)")

hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode()
fd = os.open("/tmp/htpasswd", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    f.write(f"{user}:{hashed}\n")
PY

unset PYPI_PASSWORD
exec "$@"
