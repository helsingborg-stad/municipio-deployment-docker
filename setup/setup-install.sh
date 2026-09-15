#!/usr/bin/env bash
set -euo pipefail

# Bootstraps WordPress against an empty database, respecting the same
# WP_ALLOW_MULTISITE / SUBDOMAIN_INSTALL environment variables used by
# setup-htaccess.sh and wp-config. This is a no-op once WordPress
# has already been installed, so it is safe to run on every container start.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

ALLOW_MULTISITE="${WP_CONF_WP_ALLOW_MULTISITE:-${WP_ALLOW_MULTISITE:-false}}"
SUBDOMAIN="${WP_CONF_SUBDOMAIN_INSTALL:-${SUBDOMAIN_INSTALL:-false}}"
ENABLE_LS_CACHE="${WP_CONF_ENABLE_LS_CACHE:-${ENABLE_LS_CACHE:-false}}"

activate_required_plugins() {
    local activation_args=(--allow-root --skip-plugins --skip-themes)

    if [[ "${ALLOW_MULTISITE}" == "true" ]]; then
        activation_args+=(--network)
    fi

    wp plugin activate advanced-custom-fields-pro "${activation_args[@]}"

    if [[ "${ENABLE_LS_CACHE}" == "true" ]]; then
        wp plugin activate litespeed-cache "${activation_args[@]}"
    fi
}

if wp core is-installed --allow-root; then
    activate_required_plugins

    # .htaccess isn't persisted across container restarts/rebuilds, but the
    # permalink structure and any rewrite rules plugins register (both stored
    # in the database, which IS persisted via the db-data volume) are. Flush
    # them back into .htaccess every time the container starts so rewrite
    # rules generated at runtime survive a restart without needing a mount.
    wp rewrite flush --hard --allow-root
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

DOMAIN_CURRENT_SITE="${WP_CONF_DOMAIN_CURRENT_SITE:-${DOMAIN_CURRENT_SITE:-}}"
WP_HOME="${WP_CONF_WP_HOME:-${WP_HOME:-}}"
WP_ADMIN_USER="${WP_CONF_WP_ADMIN_USER:-${WP_ADMIN_USER:-}}"
WP_ADMIN_PASSWORD="${WP_CONF_WP_ADMIN_PASSWORD:-${WP_ADMIN_PASSWORD:-}}"
WP_ADMIN_EMAIL="${WP_CONF_WP_ADMIN_EMAIL:-${WP_ADMIN_EMAIL:-}}"
WP_SITE_TITLE="${WP_CONF_WP_SITE_TITLE:-${WP_SITE_TITLE:-WordPress}}"

: "${WP_ADMIN_USER:?WP_ADMIN_USER (or WP_CONF_WP_ADMIN_USER) must be set to install WordPress}"
: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD (or WP_CONF_WP_ADMIN_PASSWORD) must be set to install WordPress}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL (or WP_CONF_WP_ADMIN_EMAIL) must be set to install WordPress}"

if [[ "${ALLOW_MULTISITE}" == "true" ]]; then
    : "${DOMAIN_CURRENT_SITE:?DOMAIN_CURRENT_SITE (or WP_CONF_DOMAIN_CURRENT_SITE) must be set to install a WordPress multisite network}"
    INSTALL_URL="${DOMAIN_CURRENT_SITE}"
else
    : "${WP_HOME:?WP_HOME (or WP_CONF_WP_HOME) must be set to install WordPress}"
    INSTALL_URL="${WP_HOME}"
fi

INSTALL_ARGS=(
    --url="${INSTALL_URL}"
    --title="${WP_SITE_TITLE}"
    --admin_user="${WP_ADMIN_USER}"
    --admin_password="${WP_ADMIN_PASSWORD}"
    --admin_email="${WP_ADMIN_EMAIL}"
    --skip-email
    --allow-root
)

if [[ "${ALLOW_MULTISITE}" == "true" ]]; then
    if [[ "${SUBDOMAIN}" == "true" ]]; then
        INSTALL_ARGS+=(--subdomains)
    fi
    # Installs core, creates the network row in wp_site, and registers the
    # main site in wp_blogs in a single step (no manual "Network Setup" needed).
    wp core multisite-install "${INSTALL_ARGS[@]}"
else
    wp core install "${INSTALL_ARGS[@]}"
fi

activate_required_plugins
wp rewrite flush --hard --allow-root
