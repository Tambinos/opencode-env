#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
OPENCODE_DIR="$CONFIG_HOME/opencode"
PLUGIN_DIR="$OPENCODE_DIR/plugins"
CAVEMAN_SRC="${CAVEMAN_SRC:-/opt/caveman}"
RTK_PLUGIN_SRC="${RTK_PLUGIN_SRC:-/opt/opencode-tools/rtk.ts}"
RTK_VERSION="${RTK_VERSION:-v1.1.0}"
PONYTAIL_PLUGIN="${PONYTAIL_PLUGIN:-@dietrichgebert/ponytail@5.3.2}"

mkdir -p "$PLUGIN_DIR"

# Caveman: native OpenCode plugin, commands, agents, skills and AGENTS.md rules.
if [ -f "$CAVEMAN_SRC/installer/install.js" ]; then
  if XDG_CONFIG_HOME="$CONFIG_HOME" node "$CAVEMAN_SRC/installer/install.js" \
      --only opencode --non-interactive >/tmp/caveman-opencode-install.log 2>&1; then
    :
  else
    echo "[opencode-tools] caveman setup failed; see /tmp/caveman-opencode-install.log" >&2
    sed -n '1,40p' /tmp/caveman-opencode-install.log >&2 || true
  fi
else
  echo "[opencode-tools] caveman source not found at $CAVEMAN_SRC; skipping" >&2
fi

# RTK binary: reinstalled on boot because /usr/local/bin is not a mounted volume.
if ! command -v rtk >/dev/null 2>&1; then
  if curl -fsSL "https://raw.githubusercontent.com/rtk-ai/rtk/${RTK_VERSION}/install.sh" \
      | RTK_VERSION="$RTK_VERSION" RTK_INSTALL_DIR=/usr/local/bin sh >/tmp/rtk-install.log 2>&1; then
    echo "[opencode-tools] installed RTK ${RTK_VERSION}"
  else
    echo "[opencode-tools] RTK install failed; see /tmp/rtk-install.log" >&2
    sed -n '1,40p' /tmp/rtk-install.log >&2 || true
  fi
fi

# RTK: OpenCode auto-discovers plugins from the global plugins directory.
if [ -f "$RTK_PLUGIN_SRC" ]; then
  if ! cmp -s "$RTK_PLUGIN_SRC" "$PLUGIN_DIR/rtk.ts" 2>/dev/null; then
    cp "$RTK_PLUGIN_SRC" "$PLUGIN_DIR/rtk.ts"
    echo "[opencode-tools] installed RTK plugin"
  fi
else
  echo "[opencode-tools] RTK plugin not found at $RTK_PLUGIN_SRC; skipping" >&2
fi

# Ponytail: declared as an npm plugin in opencode.jsonc.
node "$SCRIPT_DIR/scripts/opencode-add-plugin.mjs" "$OPENCODE_DIR" "$PONYTAIL_PLUGIN"
