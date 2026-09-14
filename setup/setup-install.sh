#!/usr/bin/env bash
set -euo pipefail

# Bootstraps WordPress against an empty database, respecting the same
# WP_ALLOW_MULTISITE / SUBDOMAIN_INSTALL environment variables used by
# setup-config.sh and setup-htaccess.sh. This is a no-op once WordPress
# has already been installed, so it is safe to run on every container start.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if wp core is-installed --allow-root; then
    exit 0
fi

MAX_TRIES=10
COUNT=0
until wp db check --allow-root; do
    COUNT=$((COUNT + 1))
    if [[ "$COUNT" -ge "$MAX_TRIES" ]]; then
        echo "setup-install.sh: database never became reachable, aborting install." >&2
        exit 1
    fi
    sleep 2
done

: "${DOMAIN_CURRENT_SITE:?DOMAIN_CURRENT_SITE must be set to install WordPress}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER must be set to install WordPress}"
: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD must be set to install WordPress}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL must be set to install WordPress}"

INSTALL_ARGS=(
    --url="${DOMAIN_CURRENT_SITE}"
    --title="${WP_SITE_TITLE:-WordPress}"
    --admin_user="${WP_ADMIN_USER}"
    --admin_password="${WP_ADMIN_PASSWORD}"
    --admin_email="${WP_ADMIN_EMAIL}"
    --skip-email
    --allow-root
)

if [[ "${WP_ALLOW_MULTISITE:-false}" == "true" ]]; then
    if [[ "${SUBDOMAIN_INSTALL:-false}" == "true" ]]; then
        INSTALL_ARGS+=(--subdomains)
    fi
    # Installs core, creates the network row in wp_site, and registers the
    # main site in wp_blogs in a single step (no manual "Network Setup" needed).
    wp core multisite-install "${INSTALL_ARGS[@]}"
else
    wp core install "${INSTALL_ARGS[@]}"
fi
