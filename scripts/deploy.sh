#!/bin/sh
set -e  # Exit on any error
cd "$(dirname "$0")/.."  # run from the repository root

if [ ! -f .env ]; then
    echo "Missing .env: copy .env.example to .env and set PYPI_USERNAME / PYPI_PASSWORD." >&2
    exit 1
fi

echo "Building image and (re)starting container..."
docker compose build --pull
docker compose up -d

echo "Removing dangling images..."
docker image prune -f

docker compose ps
