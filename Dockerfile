FROM node:22-bookworm-slim

ARG CAVEMAN_VERSION=v4.0.1
ARG RTK_VERSION=v1.1.0
ARG PONYTAIL_VERSION=5.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*
# Install Github client
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    openssh-client \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Install RTK (token-reducing shell proxy) and its OpenCode plugin
RUN curl -fsSL "https://raw.githubusercontent.com/rtk-ai/rtk/${RTK_VERSION}/install.sh" \
    | RTK_VERSION="${RTK_VERSION}" RTK_INSTALL_DIR=/usr/local/bin sh \
    && rtk --version
RUN mkdir -p /opt/opencode-tools \
    && curl -fsSL "https://raw.githubusercontent.com/rtk-ai/rtk/${RTK_VERSION}/hooks/opencode/rtk.ts" \
       -o /opt/opencode-tools/rtk.ts

# Caveman: keep the source so the OpenCode plugin can be installed without network
RUN mkdir -p /opt/caveman \
    && curl -fsSL "https://github.com/JuliusBrussee/caveman/archive/refs/tags/${CAVEMAN_VERSION}.tar.gz" \
       | tar -xz --strip-components=1 -C /opt/caveman

# Caveman CLI (proxy/shrink/browse helpers) needs Node >= 22.13
RUN npm install -g "@caveman-ai/cli@${CAVEMAN_VERSION#v}"

# Install OpenCode CLI globally (if not already baked into an upstream image)
RUN npm install -g opencode-ai

ENV PONYTAIL_PLUGIN="@dietrichgebert/ponytail@${PONYTAIL_VERSION}"
