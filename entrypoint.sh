#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$GITHUB_URL" ]; then
    echo "Error: GITHUB_URL environment variable is required"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    exit 1
fi

# Set runner name (default to hostname if not provided)
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-/home/runner/_work}"

# Create work directory
mkdir -p "$RUNNER_WORKDIR"

# Get registration token from GitHub API
# Determine if this is an org or repo URL
if [[ "$GITHUB_URL" =~ ^https://github.com/([^/]+)$ ]]; then
    # Organization URL
    ORG="${BASH_REMATCH[1]}"
    API_URL="https://api.github.com/orgs/${ORG}/actions/runners/registration-token"
elif [[ "$GITHUB_URL" =~ ^https://github.com/([^/]+)/([^/]+)$ ]]; then
    # Repository URL
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    API_URL="https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/registration-token"
else
    echo "Error: Invalid GITHUB_URL format. Expected https://github.com/ORG or https://github.com/OWNER/REPO"
    exit 1
fi

echo "Requesting registration token from: $API_URL"

REGISTRATION_TOKEN=$(curl -s -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$API_URL" | jq -r .token)

if [ -z "$REGISTRATION_TOKEN" ] || [ "$REGISTRATION_TOKEN" = "null" ]; then
    echo "Error: Failed to get registration token. Check your GITHUB_TOKEN permissions."
    exit 1
fi

echo "Successfully obtained registration token"

# Configure the runner
cd /home/runner/actions-runner

./config.sh \
    --url "$GITHUB_URL" \
    --token "$REGISTRATION_TOKEN" \
    --name "$RUNNER_NAME" \
    --work "$RUNNER_WORKDIR" \
    --labels "${RUNNER_LABELS:-self-hosted,docker}" \
    --unattended \
    --replace

# Cleanup function for graceful shutdown
cleanup() {
    echo "Caught signal, removing runner..."
    ./config.sh remove --token "$REGISTRATION_TOKEN" || true
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# Run the runner
./run.sh &

# Wait for the runner process
wait $!
