#!/usr/bin/env bash
set -euo pipefail

# We have 3 htaccewss files
# 1. .htaccess
# 2. .htaccess-multisite-subdomain
# 3. .htaccess-multisite-subfolder

# We should use the correct one determined by the envs passed to the container.
# The one that fits, should be named .htaccess
# The others should be removed
HTACCESS_FILES=("htaccess/.htaccess" "htaccess/.htaccess-multisite-subdomain" "htaccess/.htaccess-multisite-subfolder")

# So if WP_ALLOW_MULTISITE is true and SUBDOMAIN_INSTALL is true use .htaccess-multisite-subdomain
# If WP_ALLOW_MULTISITE is true and SUBDOMAIN_INSTALL is false use .htaccess-multisite-subfolder
# Otherwise use .htaccess
if [[ "${WP_ALLOW_MULTISITE:-false}" == "true" ]]; then
    if [[ "${SUBDOMAIN_INSTALL:-false}" == "true" ]]; then
        SELECTED_HTACCESS="htaccess/.htaccess-multisite-subdomain"
    else
        SELECTED_HTACCESS="htaccess/.htaccess-multisite-subfolder"
    fi
else
    SELECTED_HTACCESS="htaccess/.htaccess"
fi

for FILE in "${HTACCESS_FILES[@]}"; do
    if [[ "$FILE" == "$SELECTED_HTACCESS" ]]; then
        if [[ "$FILE" != "htaccess/.htaccess" ]]; then
            cp "$FILE" "htaccess/.htaccess"
        fi
    fi
done