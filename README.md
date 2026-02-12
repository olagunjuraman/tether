# MLC-LLM DevOps — Tether Data Take-Home

Production-quality CI/CD workflow for the [MLC-LLM](https://github.com/mlc-ai/mlc-llm)
codebase: local development, automated testing, and cross-platform wheel builds published
to **GHCR** and **GitHub Releases**.

## Deliverables

| # | Deliverable | Location |
|---|-------------|----------|
| 1 | **Multipurpose Docker image** | [`docker/Dockerfile`](docker/Dockerfile) |
| 2 | **Automated tests** | [`tests/test_infra.py`](tests/test_infra.py) |
| 3 | **CI/CD pipeline** | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) |
| 4 | **Documentation** | [`docs/README.md`](docs/README.md) |

## Quick start

```bash
# Clone MLC-LLM with submodules
git clone --recursive https://github.com/mlc-ai/mlc-llm.git && cd mlc-llm

# Copy this repo's files into the clone
# (or use this repo as a fork with these files already in place)

# Build the Docker image
docker build -f docker/Dockerfile -t mlc-llm-dev .

# Interactive dev shell
docker run -it --rm -v "$(pwd):/workspace" mlc-llm-dev

# One-shot wheel build
docker run --rm -v "$(pwd):/workspace" mlc-llm-dev build
ls dist/*.whl

# Run upstream tests inside Docker
docker run --rm -v "$(pwd):/workspace" mlc-llm-dev test
```

## Pipeline overview

```text
lint --> test --+--> docker (GHCR) --> wheel-linux --+
                |                                    +--> release (tag v* only)
                +--> wheel-windows ------------------+
```

See [`docs/README.md`](docs/README.md) for full details on prerequisites, dependencies,
build instructions, and workflow structure.
