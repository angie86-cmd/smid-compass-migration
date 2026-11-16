"""Loads the unmodified, validated SMID Compass workflow YAML into Microsoft
Agent Framework's declarative WorkflowFactory, binds it to the real live
Foundry agents (no recreation), and runs one input message through it.

Usage:
    python -m smid_compass.run_workflow "Necesito renovar mi pasaporte venezolano desde Alemania. ¿Qué debo hacer?"
"""

import asyncio
import sys
from pathlib import Path

from agent_framework.declarative import WorkflowFactory

from .agents import build_agent_registry

WORKFLOW_YAML_PATH = Path(__file__).resolve().parents[2] / "workflows" / "SMID-compass-workflow.yaml"


async def run_once(message: str) -> None:
    agents = build_agent_registry()
    factory = WorkflowFactory(agents=agents)
    workflow = factory.create_workflow_from_yaml_path(WORKFLOW_YAML_PATH)

    result = await workflow.run(message)

    print(f"status: {result.status if hasattr(result, 'status') else 'n/a'}")
    outputs = result.get_outputs() if hasattr(result, "get_outputs") else []
    print(f"outputs ({len(outputs)}):")
    for o in outputs:
        print("---")
        print(o)


async def run_with_trace(message: str) -> dict:
    """Runs the workflow and captures a structured execution trace: ordered
    executor invocations/outputs (node id + event type + data preview) and
    the final outputs list. Used by the validation suite to document exactly
    which nodes ran, in what order, and what each one produced/skipped.
    """
    agents = build_agent_registry()
    factory = WorkflowFactory(agents=agents)
    workflow = factory.create_workflow_from_yaml_path(WORKFLOW_YAML_PATH)

    trace: list[dict] = []
    error: str | None = None
    try:
        events = workflow.run(message, stream=True, include_status_events=True)
        async for event in events:
            executor_id = getattr(event, "executor_id", None)
            event_type = getattr(event, "type", None)
            if executor_id is None:
                continue
            data = getattr(event, "data", None)
            # Only string payloads (agent output text) are human-readable here;
            # other event data is internal framework objects, not useful in a report.
            data_preview = data if isinstance(data, str) else None
            trace.append({"executor_id": executor_id, "event_type": event_type, "data_preview": data_preview})
        final = await events.get_final_response()
        outputs = [str(o) for o in final.get_outputs()]
    except Exception as exc:  # noqa: BLE001 - validation harness must capture, not raise
        outputs = []
        error = f"{type(exc).__name__}: {exc}"

    node_sequence = [t["executor_id"] for t in trace if t["event_type"] == "output"]
    return {
        "message": message,
        "trace": trace,
        "node_sequence": node_sequence,
        "outputs": outputs,
        "error": error,
    }


def main() -> None:
    message = sys.argv[1] if len(sys.argv) > 1 else (
        "Necesito renovar mi pasaporte venezolano desde Alemania. ¿Qué debo hacer?"
    )
    asyncio.run(run_once(message))


if __name__ == "__main__":
    main()
