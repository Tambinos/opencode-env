#!/bin/sh
set -e

# 1. DNS fix for Kata microVM
printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf

# 2. Allow Git to operate on mounted host folders
git config --system --add safe.directory "*"

# 3. Apply Git URL rewrite system-wide
if [ -n "$GITHUB_TOKEN" ]; then
    echo "[entrypoint] GITHUB_TOKEN detected. Setting up HTTPS rewrite in /etc/gitconfig..."
    git config --system url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
    git config --system --add url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
    git config --system --add url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"
    echo "[entrypoint] Git rewrite configured successfully."
else
    echo "[entrypoint] ERROR: GITHUB_TOKEN is empty! Git rewrite was SKIPPED." >&2
fi

# Execute the container's default command
exec "$@"
