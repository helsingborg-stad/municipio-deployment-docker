#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# We have 3 htaccewss files
# 1. htaccess/.htaccess
# 2. htaccess/.htaccess-multisite-subdomain
# 3. htaccess/.htaccess-multisite-subfolder

# The selected one is copied to the document root as ".htaccess", which is
# where OpenLiteSpeed's autoLoadHtaccess/RewriteFile config actually reads it
# from (not the "htaccess/" source folder itself).

# So if WP_ALLOW_MULTISITE is true and SUBDOMAIN_INSTALL is true use .htaccess-multisite-subdomain
# If WP_ALLOW_MULTISITE is true and SUBDOMAIN_INSTALL is false use .htaccess-multisite-subfolder
# Otherwise use .htaccess
ALLOW_MULTISITE="${WP_CONF_WP_ALLOW_MULTISITE:-${WP_ALLOW_MULTISITE:-false}}"
SUBDOMAIN="${WP_CONF_SUBDOMAIN_INSTALL:-${SUBDOMAIN_INSTALL:-false}}"
ENABLE_LS_CACHE="${WP_CONF_ENABLE_LS_CACHE:-${ENABLE_LS_CACHE:-false}}"

if [[ "$ALLOW_MULTISITE" == "true" ]]; then
    if [[ "$SUBDOMAIN" == "true" ]]; then
        SELECTED_HTACCESS="htaccess/.htaccess-multisite-subdomain"
    else
        SELECTED_HTACCESS="htaccess/.htaccess-multisite-subfolder"
    fi
else
    SELECTED_HTACCESS="htaccess/.htaccess"
fi

if [[ "$ENABLE_LS_CACHE" == "true" ]]; then
    cat << 'EOF' > ".htaccess"
# BEGIN LSCACHE
## LITESPEED WP CACHE PLUGIN - Do not edit the contents of this block! ##
<IfModule mod_rewrite.c>
RewriteEngine on
RewriteRule litespeed/debug/.*\.log$ - [F,L]
RewriteRule \.litespeed_conf\.dat - [F,L]
</IfModule>
<IfModule LiteSpeed>
CacheLookup on
RewriteRule .* - [E=Cache-Control:no-autoflush]

### marker ASYNC start ###
RewriteCond %{REQUEST_URI} /wp-admin/admin-ajax\.php
RewriteCond %{QUERY_STRING} action=async_litespeed
RewriteRule .* - [E=noabort:1]
### marker ASYNC end ###

### marker DROPQS start ###
CacheKeyModify -qs:fbclid
CacheKeyModify -qs:gclid
CacheKeyModify -qs:utm*
CacheKeyModify -qs:_ga
### marker DROPQS end ###

</IfModule>
## LITESPEED WP CACHE PLUGIN - Do not edit the contents of this block! ##
# END LSCACHE
# BEGIN NON_LSCACHE
## LITESPEED WP CACHE PLUGIN - Do not edit the contents of this block! ##
## LITESPEED WP CACHE PLUGIN - Do not edit the contents of this block! ##
# END NON_LSCACHE
EOF
    cat "$SELECTED_HTACCESS" >> ".htaccess"
else
    cp "$SELECTED_HTACCESS" ".htaccess"
fi
