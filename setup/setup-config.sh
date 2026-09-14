#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup configuration for the application based on environment variables
# Replace placeholders in the configuration files with the corresponding environment variables
# Placeholder pattern is (#VARIABLE_NAME#), optionally with a fallback value
# used when the env var is unset/empty: (#VARIABLE_NAME|default#). Prefix a
# variable with optional: to remove its entire config line when it is empty:
# (#optional:VARIABLE_NAME#).
#
# Keep placeholders quoted in the config file, e.g. define('X', "(#X|30#)");
# — an unquoted "#" starts a PHP line comment and corrupts the file. By
# default the substituted value stays a quoted PHP string. Two prefixes on
# the default change that:
#   - (#X|int:30#)  -> quotes are stripped, value cast to a real PHP int
#   - true/false values are always unquoted regardless of the prefix above,
#     since PHP has no way to write a quoted boolean literal ('false' as a
#     string is truthy).

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

# Sed's own delimiter, kept distinct from the "|" used in the placeholder
# default syntax (and anything else likely to show up in a default/value).
SED_DELIM=$'\x01'

escape_sed_replacement() {
    printf '%s' "$1" | sed -e "s/[\\\\&${SED_DELIM}]/\\\\&/g"
}

escape_sed_pattern() {
    printf '%s' "$1" | sed -e "s/[.[*^\$\\\\${SED_DELIM}]/\\\\&/g"
}

replace_in_file() {
    sed -i.bak "$1" "$2"
    rm -f "$2.bak"
}

for FILE in "${CONFIG_FILES[@]}"; do
    # Find all placeholders in the current file and replace them with the corresponding environment variables.
    # A placeholder may carry a "(#VAR|default#)" fallback; that default is used
    # when the env var is unset/empty. An "(#optional:VAR#)" placeholder removes
    # its entire config line when the env var is unset/empty.
    for PLACEHOLDER in $(grep -oE '\(#[A-Za-z_][A-Za-z0-9_]*(\|[^#]*)?#\)|\(#optional:[A-Za-z_][A-Za-z0-9_]*#\)' "$FILE" | sort -u); do
        INNER="${PLACEHOLDER#(#}"
        INNER="${INNER%#)}"
        OPTIONAL="false"
        if [[ "$INNER" == optional:* ]]; then
            OPTIONAL="true"
            INNER="${INNER#optional:}"
        fi
        VAR="${INNER%%|*}"
        DEFAULT=""
        TYPE=""
        if [[ "$INNER" == *\|* ]]; then
            DEFAULT="${INNER#*|}"
            if [[ "$DEFAULT" == int:* ]]; then
                TYPE="int"
                DEFAULT="${DEFAULT#int:}"
            fi
        fi
        VALUE="${!VAR:-$DEFAULT}"
        PATTERN="$(escape_sed_pattern "$PLACEHOLDER")"
        if [[ "$OPTIONAL" == "true" && -z "$VALUE" ]]; then
            replace_in_file "/${PATTERN}/d" "$FILE"
        elif [[ "$TYPE" == "int" ]]; then
            if [[ ! "$VALUE" =~ ^-?[0-9]+$ ]]; then
                echo "setup-config.sh: '${VAR}' must be an integer, got '${VALUE}'" >&2
                exit 1
            fi
            # Strip whichever quote style wraps the placeholder so the
            # substituted value becomes a real PHP int, not a numeric string.
            replace_in_file "s${SED_DELIM}['\"]${PATTERN}['\"]${SED_DELIM}${VALUE}${SED_DELIM}g" "$FILE"
        elif [[ "$VALUE" == "true" || "$VALUE" == "false" ]]; then
            # Strip whichever quote style (single or double) wraps the
            # placeholder in the source file, since a quoted 'false'/"false"
            # string is truthy in PHP.
            replace_in_file "s${SED_DELIM}['\"]${PATTERN}['\"]${SED_DELIM}${VALUE}${SED_DELIM}g" "$FILE"
        else
            VALUE="$(escape_sed_replacement "$VALUE")"
            replace_in_file "s${SED_DELIM}${PATTERN}${SED_DELIM}${VALUE}${SED_DELIM}g" "$FILE"
        fi
    done
done
