# OpenCode Kata Sandbox

A secure, isolated development environment running inside a dedicated hardware-virtualized microVM via **Kata Containers**. It allows autonomous coding agents to run commands and edit code without risk of escaping into the host system, while preserving Git and GitHub integration.

---

## Prerequisites

Hardware-assisted virtualization must be supported and enabled on the host.

```bash
# Verify KVM support (must return > 0)
egrep -c '(vmx|svm)' /proc/cpuinfo

# Ensure KVM device exists and is accessible
ls -la /dev/kvm
sudo chmod 666 /dev/kvm   # If non-root access is required

```

---

## 1. Install Kata Containers

Download and unpack the latest static release of Kata Containers:

```bash
export VERSION=$(curl -sSL https://api.github.com/repos/kata-containers/kata-containers/releases/latest | jq -r .tag_name)

case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  s390x)   ARCH=s390x ;;
  ppc64le) ARCH=ppc64le ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

curl -fsSL -o kata-static.tar.zst \
  "https://github.com/kata-containers/kata-containers/releases/download/${VERSION}/kata-static-${VERSION}-${ARCH}.tar.zst"

# Unpack to /opt/kata
sudo tar -xvf kata-static.tar.zst -C /
rm -f kata-static.tar.zst

```

### Configure System Symlinks

Link the Rust shim binary into your system `$PATH` and link the default `runtime-rs` configuration:

```bash
# Link the containerd shim
sudo ln -sf /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 /usr/local/bin/containerd-shim-kata-v2

# Create config directory and link runtime-rs QEMU config
sudo mkdir -p /etc/kata-containers
sudo ln -sf /opt/kata/share/defaults/kata-containers/runtime-rs/configuration.toml /etc/kata-containers/configuration.toml

```

---

## 2. Configure Runtimes

### Docker (`/etc/docker/daemon.json`)

Configure Docker to register the Kata shim-v2 runtime:

```bash
sudo vim /etc/docker/daemon.json

```

```json
{
  "runtimes": {
    "kata": {
      "runtimeType": "io.containerd.kata.v2"
    }
  }
}

```

### Containerd (`/etc/containerd/config.toml`)

Ensure the Kata runtime plugin is registered under Containerd's CRI configuration:

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
  privileged_without_host_devices = false

```

### Restart Daemons

Apply the new configuration:

```bash
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl restart docker

```

---

## 3. Environment & Secrets Setup

Create a `.env` file in the sandbox directory:

```bash
cp .env.example .env

```

Define your GitHub Personal Access Token (PAT):

```env
SANDBOX_GH_TOKEN=ghp_yourPersonalAccessTokenOrFineGrainedToken

```

> **Note on SSH Sockets:** Do **not** bind-mount `${SSH_AUTH_SOCK}` into Kata Containers. Kata runs inside a virtual machine powered by `virtio-fs`, which cannot share host Unix domain sockets across the VM boundary (doing so causes `Input/output error (os error 5)`). Use `SANDBOX_GH_TOKEN` or mount dedicated private key files directly (`~/.ssh/id_ed25519`).

---

## 4. Usage

### Launching the Environment

Because OpenCode uses an interactive terminal user interface (TUI), run it directly with an attached TTY:

```bash
# Start an interactive session
docker compose run --rm opencode-dev

```

Alternatively, start it detached and attach to the container:

```bash
docker compose up -d
docker attach opencode_env

```

---

## Important Constraints & Gotchas

* **Parent Directory Sockets:** If mounting a parent directory (`..:/workspace`), make sure it does not contain Unix domain sockets or named pipes (such as `gunicorn.sock`, Redis/Postgres sockets, or test FIFOs). `virtio-fs` will fail with an I/O error when encountering them.
* **Ignored Data:** Add `sandbox_data/` to your `.gitignore`. It contains root-owned runtime cache files, local configuration, and credentials stored by the agent:
```gitignore
sandbox_data/

```


* **Verify Isolation:** Run `uname -r` inside the container. It will display Kata's guest kernel version (e.g., `6.x.x`), confirming full VM isolation from your host kernel.
