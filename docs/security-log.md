# Security Log

English | [繁體中文](security-log.zh-TW.md)

- Date: 2026-10-25
- Branch: `fix/security-upgrades`
- Scope: `Dockerfile`, `entrypoint.sh`, `compose.yaml`, `requirements.txt`, deploy scripts

## Summary

The committed plain-text password file was removed; credentials now come from environment variables and are hashed with bcrypt when the container starts. The image is pinned, runs as a non-root user with a read-only root filesystem, and installs pypiserver from hashed requirements. The way packages are stored changed, so existing deployments need a one-time migration.

## Changes

| Item | Before | After | Reason |
|---|---|---|---|
| `pypi_password.txt` | `ooo:ooo` (plain text, committed) | removed | Credentials must not live in the repository |
| Credentials | file baked into the image | `PYPI_USERNAME` / `PYPI_PASSWORD` → bcrypt `/tmp/htpasswd` at startup | No secret in the image or the repository |
| Base image | `python:3.11` (unpinned, full) | `python:3.13.17-slim-trixie` | Smaller, reproducible image |
| pypiserver install | `pip install pypiserver[passlib]` (unpinned) | uv, `requirements.txt` with hashes (pypiserver 2.4.2, bcrypt <5) | Reproducible and tamper-evident install; passlib 1.7.4 cannot use bcrypt 5 |
| Runtime | root | non-root user, read-only root filesystem, `no-new-privileges` | Limit damage if the server is compromised |
| Package storage | bind mount `~/pypi_packages` | Docker volume `packages` | Writable by the non-root user |
| `deploy.sh` | `docker system prune -f` | `docker image prune -f` | The old command removed unrelated stopped containers, networks and images |

## What you need to know

- Copy `.env.example` to `.env` and set `PYPI_USERNAME` / `PYPI_PASSWORD` before running `./deploy.sh`.
- Migrating packages from the old `~/pypi_packages` directory: run `./deploy.sh` once (this creates the `pypi-server_packages` volume), then `docker run --rm -v ~/pypi_packages:/src:ro -v pypi-server_packages:/dst alpine sh -c 'cp -a /src/. /dst/ && chown -R 10001:10001 /dst'`, then `./restart.sh`.
- The old password `ooo:ooo` is still in the Git history. Do not reuse it.
- If the server is reachable from other machines, put it behind HTTPS; otherwise the password is sent in plain text.

## Remaining issues

No known vulnerabilities remain in the pinned requirements.

## How it was verified

- Outside Docker: the entrypoint refuses to start without credentials and writes a 0600 bcrypt htpasswd.
- pypi-server rejects uploads with a wrong password, accepts `uv publish --index` with the right one, and `uv add` installs the package through `[tool.uv.sources]`.
- `docker compose config` validates.

## Not verified

- Building and running the Docker image (no Docker daemon in the test environment).
- The package migration command above.
