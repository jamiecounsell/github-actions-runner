# GitHub Actions Runner

A Docker image for running self-hosted GitHub Actions runners.

## Quick Start

Run the GitHub Actions Runner container:

```bash
docker run -d --restart always \
  --name github-runner \
  -e GITHUB_URL="https://github.com/YOUR_ORG/YOUR_REPO" \
  -e GITHUB_TOKEN="YOUR_GITHUB_TOKEN" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/jamiecounsell/github-actions-runner
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_URL` | Yes | URL of your GitHub organization or repository (e.g., `https://github.com/myorg` or `https://github.com/myorg/myrepo`) |
| `GITHUB_TOKEN` | Yes | GitHub Personal Access Token with `admin:org` scope (for org runners) or `repo` scope (for repo runners) |
| `RUNNER_NAME` | No | Name for the runner (defaults to container hostname) |
| `RUNNER_WORKDIR` | No | Working directory for the runner (defaults to `/home/runner/_work`) |
| `RUNNER_LABELS` | No | Comma-separated labels for the runner (defaults to `self-hosted,docker`) |

## Docker-in-Docker Support

To allow the runner to execute Docker commands (e.g., for building Docker images in workflows), mount the Docker socket:

```bash
-v /var/run/docker.sock:/var/run/docker.sock
```

## Building Locally

```bash
docker build -t github-actions-runner .
```

## GitHub Token Permissions

For **organization-level** runners, your token needs:
- `admin:org` scope

For **repository-level** runners, your token needs:
- `repo` scope

## License

MIT