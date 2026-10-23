#!/bin/sh
set -e

# 1. DNS fix for Kata microVM
printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf

# 2. Allow Git to operate on mounted host folders
git config --system --add safe.directory "*"

# 4. PREVENT PERMISSION LOCKS: Tell Git to keep .git/objects and refs group/world-writable
git config --system core.sharedRepository all

# 3. Apply Git URL rewrite system-wide
if [ -n "$GITHUB_TOKEN" ]; then
    echo "[entrypoint] GITHUB_TOKEN detected. Setting up HTTPS rewrite in /etc/gitconfig..."
    git config --system url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
    git config --system --add url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
    git config --system --add url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"
    echo "[entrypoint] Git rewrite configured successfully."
else
    echo "[entrypoint] GITHUB_TOKEN not set. Running in local-only mode; GitHub HTTPS rewrite skipped."
fi

# Execute the container's default command
exec "$@"
