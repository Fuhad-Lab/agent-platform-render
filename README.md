# agent-platform-render

Render deployment wrapper for the private canonical repo
`Fuhad-Lab/longhorizon-agent-platform` (the Render GitHub App cannot read
private repos outside its account, so this public wrapper installs the
platform at build time via `requirements.txt` + a build env var
`GITHUB_TOKEN`). This repo contains zero platform code and zero secrets.

The service's fixed build command (`pip install --upgrade pip && pip install
-r requirements.txt && pip install --no-deps .`) does the rest.
