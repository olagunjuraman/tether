#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Multipurpose entrypoint for MLC-LLM Docker image.
#
# Modes:
#   build   — compile native libs + produce Python wheel, then exit.
#   test    — run the upstream unit test suite, then exit.
#   shell   — drop into an interactive bash shell (default when no args).
#   <other> — exec whatever was passed (e.g. `python script.py`).
#
# The mode is selected by the first argument OR the MLC_BUILD_MODE env var.
# Runs as non-root user 'mlc' by default; sudo is available when needed.
#
# Build follows the official MLC-LLM build-from-source guide:
#   https://llm.mlc.ai/docs/install/mlc_llm.html#option-2-build-from-source
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

MODE="${1:-${MLC_BUILD_MODE:-shell}}"

# ── helpers ──────────────────────────────────────────────────────────────────

require_source() {
    if [ ! -f /workspace/CMakeLists.txt ]; then
        echo "Error: MLC-LLM source tree not found at /workspace."
        echo "Mount it:  docker run -v \$(pwd):/workspace ..."
        exit 1
    fi
}

do_build() {
    require_source
    cd /workspace

    # ── Step 1: Place cmake config ───────────────────────────────────────
    # The official guide runs `python cmake/gen_cmake_config.py` interactively.
    # For non-interactive CI/Docker builds we use a pre-generated config.cmake
    # (equivalent output of gen_cmake_config.py with Vulkan ON, CUDA OFF).
    # CMakeLists.txt looks for config.cmake in CMAKE_BINARY_DIR first, then
    # CMAKE_SOURCE_DIR — we place it in the build dir below.
    # Use sudo if the mounted workspace is owned by a different host user.
    mkdir -p build
    if [ ! -f build/config.cmake ]; then
        cp /opt/mlc-build/config.cmake build/config.cmake 2>/dev/null \
            || sudo cp /opt/mlc-build/config.cmake build/config.cmake
    fi

    # ── Step 2: Configure and build (official guide) ─────────────────────
    # Ref: mkdir -p build && cd build && cmake .. && make -j $(nproc)
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j "$(nproc)"
    cd ..

    # ── Step 3: Package as wheel ─────────────────────────────────────────
    # The official guide installs via `cd python && pip install -e .`.
    # For CI distribution we produce a wheel from the python/ subdirectory
    # so it can be uploaded as a release artifact.
    cd python
    pip wheel . --no-deps --wheel-dir /workspace/dist
    cd ..

    # ── Step 4: Validate ─────────────────────────────────────────────────
    echo ""
    echo "Build artifacts:"
    ls -1 build/libmlc_llm.so build/libtvm_runtime.so 2>/dev/null || true
    echo ""
    echo "Wheel(s) produced:"
    ls -1 dist/*.whl
}

do_test() {
    require_source
    cd /workspace
    exec pytest tests/python -m unittest -v --tb=short -x \
        -k "not engine and not endpoint"
}

# ── dispatch ─────────────────────────────────────────────────────────────────

case "$MODE" in
    build)
        do_build
        ;;
    test)
        do_test
        ;;
    shell)
        # Explicit shell mode — drop into interactive bash.
        exec /bin/bash
        ;;
    *)
        # Arbitrary command (e.g. `docker run ... mlc-llm-dev python script.py`).
        exec "$@"
        ;;
esac
