#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLS_CONF="/usr/local/lsws/conf/httpd_config.conf"

# Ensure no stale .env file exists in webroot
rm -f "$SCRIPT_DIR/../.env"

# Inject only WP_CONF_* environment variables into OpenLiteSpeed extProcessor
if [[ -f "$OLS_CONF" ]]; then
    while IFS='=' read -r name value; do
        if [[ "$name" =~ ^WP_CONF_[A-Za-z0-9_]+$ ]]; then
            sed -i "/extProcessor lsphp{/a \    env ${name}=${value}" "$OLS_CONF"
        fi
    done < <(printenv)
fi

# Run the setup-htaccess script to configure .htaccess rules
bash "$SCRIPT_DIR/setup-htaccess.sh"

# Run the setup-install script to bootstrap WordPress installation
bash "$SCRIPT_DIR/setup-install.sh"

echo "Configuration setup completed."

echo "Starting litespeed."
exec /entrypoint.sh "$@"