# ──────────────────────────────────────────────────────────────────────────────
# MLC-LLM Multipurpose Image
# Serves as both:
#   1. Development environment  (interactive shell, source mounted, dev tools)
#   2. Build environment        (non-interactive: compile + package wheel)
#
# Build:  docker build -f docker/Dockerfile -t mlc-llm-dev .
# Dev:    docker run -it --rm -v $(pwd):/workspace mlc-llm-dev
# Build:  docker run --rm -v $(pwd):/workspace mlc-llm-dev build
# ──────────────────────────────────────────────────────────────────────────────

# Use the official Python image for a reliable, exact Python version.
# Debian Bookworm base gives us a stable apt ecosystem for system packages.
ARG PYTHON_VERSION=3.13
ARG RUST_TOOLCHAIN=1.78.0
FROM python:${PYTHON_VERSION}-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive

# OCI image metadata
LABEL org.opencontainers.image.title="mlc-llm-dev" \
      org.opencontainers.image.description="Multipurpose dev/build image for MLC-LLM" \
      org.opencontainers.image.source="https://github.com/mlc-ai/mlc-llm" \
      org.opencontainers.image.licenses="Apache-2.0"

# ── System packages ──────────────────────────────────────────────────────────
# Build toolchain + Vulkan runtime/dev + dev convenience tools, in one layer.
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
        # Build toolchain
        build-essential \
        ca-certificates \
        ccache \
        cmake \
        curl \
        git \
        git-lfs \
        gosu \
        glslang-tools \
        libvulkan1 \
        libvulkan-dev \
        spirv-headers \
        spirv-tools \
        ninja-build \
        pkg-config \
        sudo \
        unzip \
        # Dev convenience tools (interactive shell)
        gdb \
        htop \
        less \
        vim \
    && rm -rf /var/lib/apt/lists/*

# ── Non-root user ────────────────────────────────────────────────────────────
# Create a non-root 'mlc' user for running builds and dev shells.
# Passwordless sudo is available for cases where root is needed (e.g. apt-get).
ARG USER_NAME=mlc
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USER_NAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME}

# ── Rust toolchain (required by tokenizers-cpp) ──────────────────────────────
# RUSTUP_HOME: shared read-only location for the toolchain (rustc, cargo binary).
# CARGO_HOME:  per-user writable location for crate registry cache and downloads.
# Re-declare ARG so it is in scope for this stage (ARGs before FROM are not).
ARG RUST_TOOLCHAIN=1.78.0
ENV RUSTUP_HOME="/opt/rust/rustup" \
    RUST_TOOLCHAIN="${RUST_TOOLCHAIN}"

# Use bash with pipefail for RUN with pipe; reset to default after
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | CARGO_HOME=/opt/rust/cargo sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --profile minimal \
    && chmod -R a+rX /opt/rust \
    && /opt/rust/cargo/bin/rustc --version
SHELL ["/bin/sh", "-c"]

# Put cargo/rustc on PATH; set CARGO_HOME to mlc user's home (writable for crate downloads).
ENV PATH="/opt/rust/cargo/bin:${PATH}" \
    CARGO_HOME="/home/mlc/.cargo"

# ── Python build tooling ─────────────────────────────────────────────────────
RUN pip install --no-cache-dir \
        pytest==8.3.3 \
        setuptools==75.6.0 \
        wheel==0.43.0

# ── ccache config (faster rebuilds in dev; host-mounted volume) ──────────────
ENV CCACHE_DIR="/workspace/.ccache" \
    CMAKE_C_COMPILER_LAUNCHER="ccache" \
    CMAKE_CXX_COMPILER_LAUNCHER="ccache"

# ── Workspace ────────────────────────────────────────────────────────────────
RUN mkdir -p /workspace && chown "${USER_UID}:${USER_GID}" /workspace
WORKDIR /workspace

# ── Bake in cmake config and entrypoint ──────────────────────────────────────
COPY docker/config.cmake /opt/mlc-build/config.cmake
COPY docker/build-entrypoint.sh /usr/local/bin/build-entrypoint.sh
RUN chmod +x /usr/local/bin/build-entrypoint.sh

# Switch to non-root user
USER ${USER_NAME}

ENTRYPOINT ["/usr/local/bin/build-entrypoint.sh"]
CMD ["shell"]
