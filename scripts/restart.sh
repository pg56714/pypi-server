#!/bin/sh
cd "$(dirname "$0")/.."  # run from the repository root
docker compose restart pypi-server
