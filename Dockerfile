FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_VERSION=2.311.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for Docker-in-Docker support via socket mount)
# Using docker.io from Ubuntu repository for simplicity
RUN apt-get update \
    && apt-get install -y docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn
RUN apt-get update \
    && apt-get install -y nodejs npm yarnpkg \
    && ln -s /usr/bin/yarnpkg /usr/bin/yarn \
    && rm -rf /var/lib/apt/lists/*

# Create runner user
RUN useradd -m -s /bin/bash runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create actions-runner directory
RUN mkdir -p /home/runner/actions-runner \
    && chown -R runner:runner /home/runner

# Download and install GitHub Actions Runner
WORKDIR /home/runner/actions-runner
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then ARCH="arm64"; \
    else echo "Error: Unsupported architecture: $ARCH. Only amd64 and arm64 are supported." && exit 1; fi \
    && curl -o actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz -L \
        https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && chown -R runner:runner /home/runner/actions-runner \
    && ./bin/installdependencies.sh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to runner user
USER runner

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
