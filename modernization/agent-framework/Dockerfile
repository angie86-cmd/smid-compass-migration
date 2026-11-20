# NOT YET USED FOR A REAL DEPLOYMENT. Prepared per the 2026-11-16 instruction to
# have a ready, locally-tested container option for Foundry Hosted Agent
# deployment, without translating/changing the declarative workflow YAML.
#
# Why a container at all, instead of Microsoft's simpler "source deployment"
# (--deploy-mode code) path: source deployment's documented Python runtimes
# (python_3_13 / python_3_14) are plain Python — they do not bundle a .NET
# runtime, and this project's declarative workflow engine (agent_framework
# .declarative -> powerfx -> clr_loader) requires CoreCLR/.NET 10 to evaluate
# the YAML's Power Fx expressions. A custom container is the documented way to
# add that non-Python runtime dependency alongside Python.
#
# Platform: linux/amd64 (x86_64), matching Foundry Hosted Agent container
# sandboxes. Build explicitly for that platform from Windows/ARM hosts:
#   docker build --platform linux/amd64 -t smid-compass-agent-framework .
#
# No `--platform=` on the FROM line itself: ACR Tasks' remote-build dependency
# scanner (used by `azd deploy` with `docker: {remoteBuild: true}`) uses a
# lightweight Dockerfile parser that does not understand `FROM --platform=...`
# and aborts the build before it starts. ACR Tasks' build agents are amd64
# Linux only, so the image's architecture is unaffected; local builds still
# get linux/amd64 via the explicit `docker build --platform` flag above.

FROM python:3.13-slim-bookworm

# .NET Runtime (runtime only, no SDK) via Microsoft's official install script,
# pinned to the EXACT version validated locally (--version, not --channel —
# --channel tracks the latest patch in a release train and can silently drift
# to a newer .NET than what was actually tested). ca-certificates/curl for the
# script itself; libicu/libssl are CoreCLR's own runtime dependencies on Debian.
ARG DOTNET_RUNTIME_VERSION=10.0.15
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl libicu72 libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --version ${DOTNET_RUNTIME_VERSION} --runtime dotnet --install-dir /usr/share/dotnet \
    && rm /tmp/dotnet-install.sh

ENV DOTNET_ROOT=/usr/share/dotnet \
    PATH="/usr/share/dotnet:${PATH}" \
    PYTHONNOUSERSITE=1 \
    PYTHONUTF8=1 \
    PYTHONIOENCODING=utf-8

WORKDIR /app

COPY pyproject.toml constraints.txt ./
COPY src/ src/
COPY workflows/ workflows/
COPY scripts/ scripts/

# --pre: agent-framework-foundry-hosting is currently prerelease (Microsoft's
# own docs state this), so the "hosting" extra needs it for this whole install.
# -c constraints.txt: pins the behavior-critical transitive packages (see
# constraints.txt for why) without hand-declaring them as direct dependencies.
RUN pip install --no-cache-dir --pre -c constraints.txt -e ".[hosting]"

# Build-time validation: fail the build (not a later deploy) if the exact
# .NET version, Python version, Power Fx/CoreCLR loading, or the unmodified
# workflow YAML's structure don't match what was actually validated.
RUN python scripts/validate_runtime.py

EXPOSE 8088

ENTRYPOINT ["python", "-m", "smid_compass.host"]
