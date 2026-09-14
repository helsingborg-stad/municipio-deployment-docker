#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup configuration for the application based on environment variables
# Replace placeholders in the configuration files with the corresponding environment variables
# Placeholder pattern is (#VARIABLE_NAME#)

CONFIG_FILES=("$SCRIPT_DIR/../config/"*.php)

SALTS_FILE="$SCRIPT_DIR/../config/salts.php"

# WordPress secret keys/salts must be unique per installation, so generate them
# at runtime rather than baking a shared value into the image.
if [[ ! -f "$SALTS_FILE" ]]; then
    {
        echo "<?php"
        echo
        for KEY in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
            VALUE="$(openssl rand -base64 64 | tr -d '\n=+/')"
            echo "define('${KEY}', '${VALUE}');"
        done
    } > "$SALTS_FILE"
fi

escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

replace_in_file() {
    sed -i.bak "$1" "$2"
    rm -f "$2.bak"
}

for FILE in "${CONFIG_FILES[@]}"; do
    # Find all placeholders in the current file and replace them with the corresponding environment variables.
    # Placeholders without a matching environment variable are replaced with an
    # empty string so no literal "(#VAR#)" values leak into the config (e.g. an
    # unset DB_COLLATE would otherwise be passed to MySQL as a bogus collation).
    for VAR in $(grep -oE '\(#[A-Za-z_][A-Za-z0-9_]*#\)' "$FILE" | sed -E 's/\(#(.*)#\)/\1/' | sort -u); do
        VALUE="${!VAR:-}"
        if [[ "$VALUE" == "true" || "$VALUE" == "false" ]]; then
            replace_in_file "s|'(#${VAR}#)'|${VALUE}|g" "$FILE"
        else
            VALUE="$(escape_sed_replacement "$VALUE")"
            replace_in_file "s|(#${VAR}#)|${VALUE}|g" "$FILE"
        fi
    done
done
