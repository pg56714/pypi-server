FROM ghcr.io/astral-sh/uv:0.13.5 AS uv

FROM python:3.13.17-slim-trixie

# Install pypiserver with uv from hashed, pinned requirements
COPY --from=uv /uv /usr/local/bin/uv
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache --require-hashes -r /tmp/requirements.txt \
    && rm /usr/local/bin/uv /tmp/requirements.txt

# Run as an unprivileged user
RUN useradd --system --uid 10001 --home-dir /pypi --create-home pypi \
    && mkdir -p /pypi/packages \
    && chown -R pypi:pypi /pypi

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER pypi
WORKDIR /pypi

EXPOSE 8010

ENTRYPOINT ["entrypoint.sh"]
CMD ["pypi-server", "run", "-p", "8010", "--passwords", "/tmp/htpasswd", "/pypi/packages"]
