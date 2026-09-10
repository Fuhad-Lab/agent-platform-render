# Daytona workspace initialization template — Option B: Daytona-deployed Nix.
#
# Two consumption paths:
#
# 1. Devcontainer build (self-hosted Daytona orchestrator, devcontainer
#    support enabled): Daytona reads this directory's devcontainer.json,
#    installs the community-standard Nix feature, and mounts /nix/store
#    with protected permissions out of the box.
#
# 2. Captured snapshot (managed Cloud staging, verified live): the
#    platform bootstraps this Dockerfile's steps inside a running sandbox
#    via the DaytonaDriver.ensure_nix() / ensure_nixpkgs() recipes, then
#    captures `agent-platform-nix-base` with POST /sandbox/{id}/snapshot.
#    Future workspaces boot from that snapshot name instantly
#    (WORKSPACE__DAYTONA_NIX_SNAPSHOT=agent-platform-nix-base).
#
# Egress note (measured from the managed cloud): github.com and
# cache.nixos.org are reachable; install.determinate.systems,
# flakehub.com, and nixos.org are connection-reset. The nix-installer
# binary therefore comes from GitHub releases.
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git sudo procps bash \
    && rm -rf /var/lib/apt/lists/*

# Non-root workspace user with passwordless sudo (matches the stock
# daytonaio/sandbox image conventions the toolbox exec expects).
RUN useradd -m -u 1001 daytona \
    && echo 'daytona ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/daytona

# Nix (Determinate Systems build, container mode: no systemd init).
RUN curl -sSf -L -o /tmp/nix-installer \
        https://github.com/DeterminateSystems/nix-installer/releases/latest/download/nix-installer-x86_64-linux \
    && chmod +x /tmp/nix-installer \
    && /tmp/nix-installer install linux --init none --no-confirm \
    && rm /tmp/nix-installer

ENV PATH=/nix/var/nix/profiles/default/bin:${PATH}
# The daemon must run for builds: the platform starts it idempotently
# (pgrep || sudo nix-daemon &) on every interaction — see
# agent_platform/workspace/daytona.py::_NIX_DAEMON_CMD.

USER daytona
WORKDIR /home/daytona

# Shallow nixpkgs clone (not the tarball route — see template notes).
RUN git clone --depth 1 https://github.com/NixOS/nixpkgs /tmp/nixpkgs || true

CMD ["sleep", "infinity"]
