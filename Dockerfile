FROM ghcr.io/astral-sh/uv:0.13.5 AS uv

FROM python:3.13.17-slim-trixie

# Install pypiserver into the system Python from uv.lock (pinned, with hashes)
COPY --from=uv /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /tmp/build/
RUN cd /tmp/build \
    && UV_PROJECT_ENVIRONMENT=/usr/local uv sync --locked --no-dev --no-install-project --no-cache \
    && rm -rf /usr/local/bin/uv /tmp/build

# Run as an unprivileged user
RUN useradd --system --uid 10001 --home-dir /pypi --create-home pypi \
    && mkdir -p /pypi/packages \
    && chown -R pypi:pypi /pypi

COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

USER pypi
WORKDIR /pypi

EXPOSE 8010

ENTRYPOINT ["entrypoint.sh"]
CMD ["pypi-server", "run", "-p", "8010", "--passwords", "/tmp/htpasswd", "/pypi/packages"]
