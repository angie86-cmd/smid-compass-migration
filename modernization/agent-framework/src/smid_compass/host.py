"""Foundry Hosted Agent entry point for the SMID Compass Agent Framework
workflow. NOT YET DEPLOYED — this wires the already-validated local workflow
(see run_workflow.py, validation/agent-framework-smoke-validation.md) to
Microsoft's `agent-framework-foundry-hosting` adapter (`ResponsesHostServer`,
currently prerelease), which exposes it over the Foundry Responses protocol
so a Foundry Hosted Agent container can serve it.

Uses `workflow=` (a fresh-graph-per-request factory), not `agent=`: hosting a
workflow via `agent=workflow.as_agent()` is explicitly deprecated by Microsoft
because a single instance would be shared, stateful, across requests from
different users — unsafe for a hosted multi-tenant service. A factory avoids
that by building a new graph (and fresh FoundryAgent references) per turn.

Local test (no Azure Hosted Agent needed, just runs the HTTP server):
    PYTHONUTF8=1 PYTHONIOENCODING=utf-8 .venv/Scripts/python -m smid_compass.host
Then POST to http://localhost:8088/responses as documented by
agent-framework-foundry-hosting.
"""

from agent_framework.declarative import WorkflowFactory
from agent_framework_foundry_hosting import (
    HostedResponseRequest,
    ResponsesHostServer,
    WorkflowTurn,
)

from .agents import build_agent_registry
from .run_workflow import WORKFLOW_YAML_PATH


def build_workflow():
    """Factory called fresh per request by ResponsesHostServer — builds a new
    graph and new live FoundryAgent references each time, since a built
    Workflow is stateful and must not be shared across concurrent requests.
    """
    agents = build_agent_registry()
    factory = WorkflowFactory(agents=agents)
    return factory.create_workflow_from_yaml_path(WORKFLOW_YAML_PATH)


def parse_response(request: HostedResponseRequest) -> WorkflowTurn:
    """Maps the Foundry Responses protocol's turn input to our workflow's
    plain-text trigger input (the YAML's `=System.LastMessage.Text`)."""
    return WorkflowTurn(input=request.get_input_text())


def main() -> None:
    server = ResponsesHostServer(workflow=build_workflow, parse_response=parse_response)
    server.run()


if __name__ == "__main__":
    main()
