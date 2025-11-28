#!/bin/bash
echo "Starting GitHub Actions Runner"

#set -e

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

# Determine API URLs based on GITHUB_URL format
if [[ "$GITHUB_URL" =~ ^https://github.com/([^/]+)$ ]]; then
    # Organization URL
    ORG="${BASH_REMATCH[1]}"
    REGISTRATION_API_URL="https://api.github.com/orgs/${ORG}/actions/runners/registration-token"
    REMOVAL_API_URL="https://api.github.com/orgs/${ORG}/actions/runners/remove-token"
elif [[ "$GITHUB_URL" =~ ^https://github.com/([^/]+)/([^/]+)$ ]]; then
    # Repository URL
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    REGISTRATION_API_URL="https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/registration-token"
    REMOVAL_API_URL="https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/remove-token"
else
    echo "Error: Invalid GITHUB_URL format. Expected https://github.com/ORG or https://github.com/OWNER/REPO"
    exit 1
fi

# Function to get a token from the GitHub API
get_token() {
    local api_url="$1"
    local token_type="$2"
    
    echo "Requesting ${token_type} token from: $api_url"
    
    local response
    local http_code
    
    # Make request and capture both response body and HTTP status code
    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$api_url")
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    if [ "$http_code" != "201" ]; then
        echo "Error: GitHub API returned HTTP $http_code for ${token_type} token request"
        echo "Response: $response"
        return 1
    fi
    
    local token
    token=$(echo "$response" | jq -r .token 2>/dev/null)
    
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "Error: Failed to parse ${token_type} token from API response"
        echo "Response: $response"
        return 1
    fi
    
    echo "$token"
}

# Get registration token
REGISTRATION_TOKEN=$(get_token "$REGISTRATION_API_URL" "registration")
if [ $? -ne 0 ] || [ -z "$REGISTRATION_TOKEN" ]; then
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
    
    # Get a removal token (different from registration token)
    local removal_token
    local get_token_exit_code=0
    removal_token=$(get_token "$REMOVAL_API_URL" "removal" 2>&1) || get_token_exit_code=$?
    
    if [ $get_token_exit_code -ne 0 ]; then
        echo "Warning: Failed to get removal token (exit code: $get_token_exit_code)"
        echo "Details: $removal_token"
        echo "Runner may need manual cleanup from GitHub UI"
    elif [ -n "$removal_token" ] && [ "$removal_token" != "null" ]; then
        ./config.sh remove --token "$removal_token" || echo "Warning: Runner removal command failed"
    else
        echo "Warning: Could not get removal token, runner may need manual cleanup"
    fi
    
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# Run the runner
./run.sh &
RUNNER_PID=$!

# Wait for the runner process
wait $RUNNER_PID
