#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the setup-config script to replace placeholders in configuration files
bash "$SCRIPT_DIR/setup-config.sh"

# Run the setup-htaccess script to configure .htaccess rules
bash "$SCRIPT_DIR/setup-htaccess.sh"

# Run the setup-install script to bootstrap WordPress installation
bash "$SCRIPT_DIR/setup-install.sh"

echo "Configuration setup completed."

echo "Starting litespeed."
exec /entrypoint.sh "$@"