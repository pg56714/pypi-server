# pypi-server (python package index)

## how to use

### add pypi-server to uv.index in pyproject.toml publish package

```toml
[tool.uv.index]
explicit = false
name = "your-project-name"
publish-url = "http://127.0.0.1:8010/"
url = "http://127.0.0.1:8010/simple/"
```

### install pypi-server package

```toml
[[tool.uv.index]]
explicit = false
name = "your-project-name"
url = "http://127.0.0.1:8010/simple/"
```

## how to deploy pypi-server

```bash
chmod +x deploy.sh
./deploy.sh
```
