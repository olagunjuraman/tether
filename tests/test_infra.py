"""Infrastructure tests — validate that CI/Docker artifacts are well-formed.

These run as part of the `test` gate job and do NOT require a GPU or a full
native build.  They check the *workflow itself* rather than the MLC-LLM runtime.
"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


# ── Dockerfile ────────────────────────────────────────────────────────────────

class TestDockerfile:
    """Validate docker/Dockerfile structure."""

    DOCKERFILE = REPO_ROOT / "docker" / "Dockerfile"

    def test_exists(self):
        assert self.DOCKERFILE.exists()

    def test_has_entrypoint(self):
        content = self.DOCKERFILE.read_text()
        assert "ENTRYPOINT" in content

    def test_has_oci_labels(self):
        content = self.DOCKERFILE.read_text()
        assert "org.opencontainers.image" in content

    def test_no_latest_base(self):
        """Base image should be pinned, not :latest."""
        first_from = [
            l for l in self.DOCKERFILE.read_text().splitlines()
            if l.strip().upper().startswith("FROM")
        ][0]
        assert ":latest" not in first_from

    def test_runs_as_non_root(self):
        """Dockerfile should switch to a non-root USER."""
        content = self.DOCKERFILE.read_text()
        user_lines = [
            l.strip() for l in content.splitlines()
            if l.strip().upper().startswith("USER")
        ]
        assert user_lines, "Dockerfile has no USER directive — container runs as root"
        # The last USER directive should not be 'root'
        assert "root" not in user_lines[-1].lower()


# ── Entrypoint script ────────────────────────────────────────────────────────

class TestEntrypoint:
    """Validate docker/build-entrypoint.sh."""

    SCRIPT = REPO_ROOT / "docker" / "build-entrypoint.sh"

    def test_exists_and_executable_bit_in_content(self):
        assert self.SCRIPT.exists()
        assert self.SCRIPT.read_text().startswith("#!/")

    def test_set_euo_pipefail(self):
        """Script must use strict bash error handling."""
        content = self.SCRIPT.read_text()
        assert "set -euo pipefail" in content

    def test_build_mode_follows_official_guide(self):
        """Build mode should follow the official cmake + make build path."""
        content = self.SCRIPT.read_text()
        # Step 2 from official guide: cmake .. && make
        assert "cmake .." in content
        assert "make -j" in content
        # Step 3: package as wheel from python/ subdirectory
        assert "pip wheel" in content


# ── CMake config ──────────────────────────────────────────────────────────────

class TestCMakeConfig:
    """Validate docker/config.cmake."""

    CONFIG = REPO_ROOT / "docker" / "config.cmake"

    def test_exists(self):
        assert self.CONFIG.exists()

    def test_sets_tvm_source_dir(self):
        content = self.CONFIG.read_text()
        assert "TVM_SOURCE_DIR" in content

    def test_vulkan_enabled(self):
        content = self.CONFIG.read_text()
        assert 'set(USE_VULKAN ON)' in content


# ── CI workflow ───────────────────────────────────────────────────────────────

class TestWorkflow:
    """Validate .github/workflows/ci.yml structure."""

    WORKFLOW = REPO_ROOT / ".github" / "workflows" / "ci.yml"

    def test_exists(self):
        assert self.WORKFLOW.exists()

    def test_has_test_job(self):
        content = self.WORKFLOW.read_text()
        assert "test:" in content or "Test" in content

    def test_has_release_job(self):
        content = self.WORKFLOW.read_text()
        assert "release:" in content or "Release" in content

    def test_docker_needs_test(self):
        content = self.WORKFLOW.read_text()
        assert "needs: test" in content or "needs: [test" in content


# ── .dockerignore ─────────────────────────────────────────────────────────────

class TestDockerIgnore:
    def test_exists(self):
        assert (REPO_ROOT / ".dockerignore").exists()
