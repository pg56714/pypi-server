# pypi-server (python package index)

A self-hosted Python package index based on [pypiserver](https://github.com/pypiserver/pypiserver), run with Docker Compose and used with [uv](https://docs.astral.sh/uv/).

## Deploy

1. Set the upload account:

   ```bash
   cp .env.example .env
   # edit .env and set PYPI_USERNAME / PYPI_PASSWORD
   ```

   The password is never stored in the image or the repository. At startup, `entrypoint.sh` hashes it with bcrypt into a password file inside the container (`/tmp/htpasswd`).

2. Build and start:

   ```bash
   ./deploy.sh
   ```

   Restart with `./restart.sh`. Packages are kept in the `packages` Docker volume.

The server listens on port `8010` (change it with `PYPI_PORT` in `.env`). It runs as a non-root user with a read-only root filesystem. Uploading requires the account; downloading is public by default. To require the account for downloads as well, add `-a download,update` to the `pypi-server run` command in the `Dockerfile` (`CMD`).

If the server is reachable from other machines, put it behind HTTPS (for example a reverse proxy); otherwise the password is sent in plain text.

## Use with uv

### Publish a package

In the package's `pyproject.toml`:

```toml
[[tool.uv.index]]
name = "private"
url = "http://127.0.0.1:8010/simple/"
publish-url = "http://127.0.0.1:8010/"
explicit = true
```

Pass the credentials through environment variables instead of writing them in files:

```bash
export UV_PUBLISH_USERNAME=your-username
export UV_PUBLISH_PASSWORD=your-password
uv build
uv publish --index private
```

### Install packages from the server

In the consuming project's `pyproject.toml`:

```toml
[[tool.uv.index]]
name = "private"
url = "http://127.0.0.1:8010/simple/"
explicit = true

[tool.uv.sources]
your-package = { index = "private" }
```

Then `uv add your-package` or `uv sync`. With `explicit = true`, only packages listed in `[tool.uv.sources]` are fetched from this index, so other packages cannot be substituted from it.

If downloads require the account, set `UV_INDEX_PRIVATE_USERNAME` and `UV_INDEX_PRIVATE_PASSWORD` (the index name in upper case).

## Upgrade pypiserver

Dependencies are pinned with hashes in `requirements.txt`. To upgrade, edit `requirements.in` and run:

```bash
uv pip compile requirements.in --python-version 3.13 --universal --generate-hashes -o requirements.txt
```

## Upgrading an old deployment

Older versions kept a plain-text password file in the repository and stored packages in `~/pypi_packages`. To move to the current setup:

1. Copy `.env.example` to `.env` and set a new `PYPI_USERNAME` / `PYPI_PASSWORD`.
2. Run `./deploy.sh` once. This creates the `pypi-server_packages` volume.
3. Copy the old packages into the volume and give them to the container user:

   ```bash
   docker run --rm -v ~/pypi_packages:/src:ro -v pypi-server_packages:/dst alpine sh -c 'cp -a /src/. /dst/ && chown -R 10001:10001 /dst'
   ```

4. Run `./restart.sh`.
