#!/bin/bash
#
# Extract variables from Makefile for SmartDNS package
# Outputs key=value pairs suitable for GITHUB_ENV
#

set -euo pipefail

MAKEFILE="${1:-Makefile}"

if [[ ! -f "$MAKEFILE" ]]; then
    echo "ERROR: Makefile not found: $MAKEFILE" >&2
    exit 1
fi

# Function to extract a variable from Makefile
extract_var() {
    local var_name="$1"
    awk -v var_name="$var_name" '
        $0 ~ "^" var_name "[[:space:]]*:?[=]" {
            sub("^" var_name "[[:space:]]*:?[=]", "", $0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            print
            exit
        }
    ' "$MAKEFILE"
}

extract_download_var() {
    local var_name="$1"
    awk -v var_name="$var_name" '
        /define Download\/smartdns-webui/ { in_block=1; next }
        in_block && /^endef[[:space:]]*$/ { exit }
        in_block && $0 ~ "^[[:space:]]*" var_name "[[:space:]]*:?[=]" {
            sub("^[[:space:]]*" var_name "[[:space:]]*:?[=]", "", $0)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
            print
            exit
        }
    ' "$MAKEFILE"
}

resolve_make_value() {
    local value="$1"
    value="${value//\$(PKG_NAME)/${PKG_NAME}}"
    value="${value//\$(PKG_VERSION)/${PKG_VERSION}}"
    value="${value//\$(PKG_SOURCE_VERSION)/${PKG_SOURCE_VERSION}}"
    value="${value//\$(SMARTDNS_WEBUI_SOURCE_VERSION)/${SMARTDNS_WEBUI_SOURCE_VERSION}}"
    printf '%s\n' "$value"
}

# Extract SmartDNS main package variables
PKG_NAME=$(extract_var PKG_NAME)
PKG_VERSION=$(extract_var PKG_VERSION)
PKG_SOURCE_URL=$(extract_var PKG_SOURCE_URL)
PKG_SOURCE_VERSION=$(extract_var PKG_SOURCE_VERSION)
PKG_SOURCE_RAW=$(extract_var PKG_SOURCE)
PKG_SOURCE_URL_FILE_RAW=$(extract_var PKG_SOURCE_URL_FILE)
PKG_MIRROR_HASH_OLD=$(extract_var PKG_MIRROR_HASH)
PKG_HASH_OLD=$(extract_var PKG_HASH)

# Extract SmartDNS WebUI variables
SMARTDNS_WEBUI_VERSION=$(extract_var SMARTDNS_WEBUI_VERSION)
SMARTDNS_WEBUI_SOURCE_URL=$(extract_var SMARTDNS_WEBUI_SOURCE_URL)
SMARTDNS_WEBUI_SOURCE_VERSION=$(extract_var SMARTDNS_WEBUI_SOURCE_VERSION)
SMARTDNS_WEBUI_SOURCE_RAW=$(extract_var SMARTDNS_WEBUI_SOURCE)
SMARTDNS_WEBUI_SOURCE_URL_FILE_RAW=$(extract_var SMARTDNS_WEBUI_SOURCE_URL_FILE)
SMARTDNS_WEBUI_HASH_OLD=$(extract_var SMARTDNS_WEBUI_HASH)
SMARTDNS_WEBUI_MIRROR_HASH_OLD=$(extract_download_var MIRROR_HASH)

PKG_SOURCE_FILE=$(resolve_make_value "${PKG_SOURCE_RAW}")
PKG_SOURCE_URL_FILE=$(resolve_make_value "${PKG_SOURCE_URL_FILE_RAW}")
SMARTDNS_WEBUI_SOURCE_FILE=$(resolve_make_value "${SMARTDNS_WEBUI_SOURCE_RAW}")
SMARTDNS_WEBUI_SOURCE_URL_FILE=$(resolve_make_value "${SMARTDNS_WEBUI_SOURCE_URL_FILE_RAW}")

echo "PKG_NAME=${PKG_NAME}"
echo "PKG_VERSION=${PKG_VERSION}"
echo "PKG_SOURCE_URL=${PKG_SOURCE_URL}"
echo "PKG_SOURCE_VERSION=${PKG_SOURCE_VERSION}"
echo "PKG_SOURCE_FILE=${PKG_SOURCE_FILE}"
echo "PKG_SOURCE_URL_FILE=${PKG_SOURCE_URL_FILE}"
echo "PKG_MIRROR_HASH_OLD=${PKG_MIRROR_HASH_OLD}"
echo "PKG_HASH_OLD=${PKG_HASH_OLD}"

echo "SMARTDNS_WEBUI_VERSION=${SMARTDNS_WEBUI_VERSION}"
echo "SMARTDNS_WEBUI_SOURCE_URL=${SMARTDNS_WEBUI_SOURCE_URL}"
echo "SMARTDNS_WEBUI_SOURCE_VERSION=${SMARTDNS_WEBUI_SOURCE_VERSION}"
echo "SMARTDNS_WEBUI_SOURCE_FILE=${SMARTDNS_WEBUI_SOURCE_FILE}"
echo "SMARTDNS_WEBUI_SOURCE_URL_FILE=${SMARTDNS_WEBUI_SOURCE_URL_FILE}"
echo "SMARTDNS_WEBUI_HASH_OLD=${SMARTDNS_WEBUI_HASH_OLD}"
echo "SMARTDNS_WEBUI_MIRROR_HASH_OLD=${SMARTDNS_WEBUI_MIRROR_HASH_OLD}"
