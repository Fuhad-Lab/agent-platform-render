# syntax=docker/dockerfile:1
# Render build wrapper for the Long-Horizon Autonomous Platform.
#
# WHY THIS EXISTS: the canonical repo (Fuhad-Lab/longhorizon-agent-platform)
# is PRIVATE, and the Render service's GitHub App cannot read private repos
# outside its own account. This wrapper is PUBLIC (it contains zero platform
# code) and clones the canonical repo at BUILD time using the service's
# GITHUB_TOKEN build env var.
#
# Token hygiene: GIT_ASKPASS supplies the token to git without embedding it
# in URLs or command lines; the helper script is created and deleted within
# a single RUN layer, so the layer diff carries no secret and `docker
# history` shows only the unexpanded literal. Render masks env-var values in
# build logs.
FROM python:3.12-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Full clone (not shallow): mission branches pushed from the runtime image
# need complete history on the remote side.
RUN set -eu; \
    printf '#!/bin/sh\ncase "$1" in *Username*) echo x-access-token;; *) echo "$GITHUB_TOKEN";; esac\n' > /askpass.sh; \
    chmod +x /askpass.sh; \
    export GIT_ASKPASS=/askpass.sh GIT_TERMINAL_PROMPT=0; \
    git clone https://github.com/Fuhad-Lab/longhorizon-agent-platform src; \
    rm -f /askpass.sh; \
    cp src/pyproject.toml src/README.md src/LICENSE .; \
    cp -r src/src ./src

RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir .

FROM python:3.12-slim

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# git: kernel coding workers push mission branches; curl: healthchecks;
# tmux + ripgrep + procps: OpenHands SDK agent tooling. On PaaS deploys this
# container IS the sandbox (the agent loop edits inside the workspace root).
RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl tmux ripgrep procps \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash platform

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /build/src /app/src

WORKDIR /app
USER platform

# Default: run the Temporal worker (the service start command overrides
# for the API gateway + embedded worker topology).
CMD ["python", "-m", "agent_platform.orchestration.worker"]
