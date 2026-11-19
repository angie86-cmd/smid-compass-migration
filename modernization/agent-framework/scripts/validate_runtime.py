"""Build-time (and post-build, re-runnable) validation for the Hosted Agent
container image. Run inside the image/container, never on the host — it
checks the versions and capabilities actually installed where the code will
run. Fails loudly (non-zero exit) on any check failure, so a `docker build`
step using this script stops the build rather than shipping a broken image.

Checks, in order:
  1. Python version matches the pinned runtime (3.13.x).
  2. .NET runtime is installed and is EXACTLY the pinned version (10.0.15),
     not merely "some 10.0.x" — a channel-based install can silently drift.
  3. agent_framework.declarative and agent_framework.foundry import cleanly
     (this alone proves Power Fx/CoreCLR loaded without crashing).
  4. The unmodified workflow YAML loads and builds via WorkflowFactory,
     producing a Workflow with the expected executor count.

Usage:
    python scripts/validate_runtime.py
"""

import subprocess
import sys
from pathlib import Path

EXPECTED_PYTHON = (3, 13)
EXPECTED_DOTNET_RUNTIME = "10.0.15"
WORKFLOW_YAML_PATH = Path(__file__).resolve().parents[1] / "workflows" / "SMID-compass-workflow.yaml"
EXPECTED_EXECUTOR_COUNT = 9  # entry + 5 InvokeAzureAgent + condition-group eval + join + 2 EndConversation


def check_python_version() -> None:
    actual = sys.version_info[:2]
    if actual != EXPECTED_PYTHON:
        raise SystemExit(f"FAIL: Python {actual[0]}.{actual[1]} != expected {EXPECTED_PYTHON[0]}.{EXPECTED_PYTHON[1]}")
    print(f"OK: Python {sys.version.split()[0]}")


def check_dotnet_runtime() -> None:
    try:
        result = subprocess.run(
            ["dotnet", "--list-runtimes"], capture_output=True, text=True, check=True, timeout=30
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise SystemExit(f"FAIL: could not run 'dotnet --list-runtimes': {exc}") from exc
    if EXPECTED_DOTNET_RUNTIME not in result.stdout:
        raise SystemExit(
            f"FAIL: expected .NET runtime {EXPECTED_DOTNET_RUNTIME} not found in:\n{result.stdout}"
        )
    print(f"OK: .NET runtime {EXPECTED_DOTNET_RUNTIME} present:\n  " + result.stdout.strip().replace("\n", "\n  "))


def check_imports() -> None:
    try:
        import agent_framework.declarative  # noqa: F401
        import agent_framework.foundry  # noqa: F401
    except Exception as exc:
        raise SystemExit(f"FAIL: agent_framework.declarative/foundry import failed (Power Fx/CoreCLR?): {exc}") from exc
    print("OK: agent_framework.declarative and agent_framework.foundry import cleanly (Power Fx/CoreCLR loaded)")


def check_workflow_builds() -> None:
    from agent_framework.declarative import WorkflowFactory

    if not WORKFLOW_YAML_PATH.exists():
        raise SystemExit(f"FAIL: workflow YAML not found at {WORKFLOW_YAML_PATH}")
    factory = WorkflowFactory()
    try:
        workflow = factory.create_workflow_from_yaml_path(WORKFLOW_YAML_PATH)
    except Exception as exc:
        raise SystemExit(f"FAIL: workflow YAML failed to load/build: {exc}") from exc
    executors = workflow.get_executors_list() if hasattr(workflow, "get_executors_list") else []
    print(f"OK: workflow YAML loaded and built ({len(executors)} executors)")
    if len(executors) != EXPECTED_EXECUTOR_COUNT:
        raise SystemExit(
            f"FAIL: expected {EXPECTED_EXECUTOR_COUNT} executors, got {len(executors)} — "
            "workflow structure may have changed unexpectedly"
        )


def main() -> None:
    check_python_version()
    check_dotnet_runtime()
    check_imports()
    check_workflow_builds()
    print("\nAll runtime validation checks passed.")


if __name__ == "__main__":
    main()
