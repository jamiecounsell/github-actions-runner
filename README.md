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
| `GITHUB_TOKEN` | Yes | GitHub Personal Access Token with `admin:org` scope (for org runners) or `repo` scope (for repo runners). See [Creating a GitHub Token](#creating-a-github-token) below. |
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

## Creating a GitHub Token

This runner requires a GitHub Personal Access Token (PAT) to register itself with GitHub. The token is used to request a short-lived registration token from the GitHub API.

### Using a Personal Access Token (Classic)

Classic tokens are recommended for personal accounts and are the simplest option to set up.

#### For Repository-Level Runners (Personal Accounts)

1. Go to [GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Click **Generate new token** > **Generate new token (classic)**
3. Give your token a descriptive name (e.g., "Self-hosted runner token")
4. Set an expiration (or select "No expiration" for long-running setups)
5. Select the following scope:
   - **`repo`** - Full control of private repositories (required for repository-level runners)
6. Click **Generate token**
7. Copy the token immediately (you won't be able to see it again)

#### For Organization-Level Runners

1. Go to [GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Click **Generate new token** > **Generate new token (classic)**
3. Give your token a descriptive name (e.g., "Self-hosted runner token")
4. Set an expiration (or select "No expiration" for long-running setups)
5. Select the following scope:
   - **`admin:org`** - Full control of orgs and teams (required for organization-level runners)
6. Click **Generate token**
7. Copy the token immediately (you won't be able to see it again)

### Using a Fine-Grained Personal Access Token

Fine-grained tokens provide more granular permissions but require organization settings to allow them. If you have a personal account without an organization, use a Classic token instead.

#### For Repository-Level Runners

1. Go to [GitHub Settings > Developer settings > Personal access tokens > Fine-grained tokens](https://github.com/settings/tokens?type=beta)
2. Click **Generate new token**
3. Give your token a descriptive name
4. Set the **Resource owner** to your account or organization
5. Under **Repository access**, select **Only select repositories** and choose your repository
6. Under **Permissions** > **Repository permissions**, set:
   - **Administration**: Read and write (required to manage self-hosted runners)
7. Click **Generate token**
8. Copy the token immediately

## Troubleshooting

### Token Permission Errors

If you see errors like:

```
Error: GitHub API returned HTTP 403 for registration token request
```

or

```
Error: Failed to get registration token. Check your GITHUB_TOKEN permissions.
```

This typically means:

1. **Insufficient permissions**: Ensure your token has the correct scopes:
   - For repository runners: `repo` scope (classic) or `Administration: Read and write` (fine-grained)
   - For organization runners: `admin:org` scope (classic)

2. **Token expired**: Check if your token has expired and generate a new one

3. **Wrong GITHUB_URL format**: Ensure your URL matches one of these formats:
   - Repository: `https://github.com/OWNER/REPO`
   - Organization: `https://github.com/ORG`

4. **Fine-grained tokens not enabled**: If using fine-grained tokens with an organization, ensure they are enabled in the organization's settings under **Settings > Third-party access > Personal access tokens**

### Runner Registration Issues

If the runner registers but fails to start jobs:

1. Check the runner logs: `docker logs github-runner`
2. Verify the runner appears in your repository's **Settings > Actions > Runners**
3. Ensure your workflows are configured to use `runs-on: self-hosted` (or your custom labels)

## Related Resources

- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases) - Official GitHub Actions runner releases
- [GitHub Runner Images](https://github.com/actions/runner-images) - Reference implementations of runner images from GitHub
- [Self-hosted Runners Documentation](https://docs.github.com/en/actions/hosting-your-own-runners) - Official GitHub documentation for self-hosted runners

## License

MIT