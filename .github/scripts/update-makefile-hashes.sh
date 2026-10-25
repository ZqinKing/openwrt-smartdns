#!/bin/bash
#
# Calculate new hashes and update Makefile
# Usage: update-makefile-hashes.sh <download_dir>
#

set -euo pipefail

DL_DIR="${1:-dl}"
MAKEFILE="${2:-Makefile}"

# Required environment variables
: "${PKG_NAME:?PKG_NAME is required}"
: "${PKG_VERSION:?PKG_VERSION is required}"

SMARTDNS_SOURCE_FILE="${PKG_SOURCE_FILE:-${PKG_NAME}-${PKG_VERSION}.tar.zst}"
SMARTDNS_WEBUI_SOURCE_FILE="${SMARTDNS_WEBUI_SOURCE_FILE:-smartdns-webui-${SMARTDNS_WEBUI_VERSION:-}.tar.gz}"
SMARTDNS_TARBALL="${DL_DIR}/${SMARTDNS_SOURCE_FILE}"
WEBUI_TARBALL="${DL_DIR}/${SMARTDNS_WEBUI_SOURCE_FILE}"

# Verify files exist
if [[ ! -f "$SMARTDNS_TARBALL" ]]; then
    echo "ERROR: SmartDNS tarball not found: $SMARTDNS_TARBALL" >&2
    exit 1
fi

if [[ ! -f "$WEBUI_TARBALL" ]]; then
    echo "ERROR: WebUI tarball not found: $WEBUI_TARBALL" >&2
    exit 1
fi

echo "==> Calculating new hashes..."

NEW_SMARTDNS_HASH=$(sha256sum "$SMARTDNS_TARBALL" | awk '{print $1}')
NEW_WEBUI_HASH=$(sha256sum "$WEBUI_TARBALL" | awk '{print $1}')

echo "    SmartDNS: ${PKG_HASH_OLD:-${PKG_MIRROR_HASH_OLD:-}} -> ${NEW_SMARTDNS_HASH}"
echo "    WebUI:    ${SMARTDNS_WEBUI_HASH_OLD:-${SMARTDNS_WEBUI_MIRROR_HASH_OLD:-}} -> ${NEW_WEBUI_HASH}"

echo "==> Updating Makefile..."

replace_hash() {
    local field="$1"
    local old_hash="$2"
    local new_hash="$3"
    local matches

    if [[ -z "${old_hash}" ]]; then
        echo "ERROR: ${field} hash is missing from ${MAKEFILE}" >&2
        exit 1
    fi

    matches=$(awk -v field="${field}" -v hash="${old_hash}" '
        {
            if ($0 !~ "^[[:space:]]*" field ":=") {
                next
            }
            line = $0
            while ((position = index(line, hash)) > 0) {
                count++
                line = substr(line, position + length(hash))
            }
        }
        END { print count + 0 }
    ' "${MAKEFILE}")

    if [[ "${matches}" -ne 1 ]]; then
        echo "ERROR: expected exactly one ${field} hash in ${MAKEFILE}, found ${matches}" >&2
        exit 1
    fi

    sed -i -E "s|^([[:space:]]*${field}:=)${old_hash}$|\1${new_hash}|" "${MAKEFILE}"
}

if [[ -n "${PKG_HASH_OLD:-}" ]]; then
    replace_hash "PKG_HASH" "${PKG_HASH_OLD}" "${NEW_SMARTDNS_HASH}"
elif [[ -n "${PKG_MIRROR_HASH_OLD:-}" ]]; then
    replace_hash "PKG_MIRROR_HASH" "${PKG_MIRROR_HASH_OLD}" "${NEW_SMARTDNS_HASH}"
else
    echo "ERROR: neither PKG_HASH nor PKG_MIRROR_HASH is set in ${MAKEFILE}" >&2
    exit 1
fi

if [[ -n "${SMARTDNS_WEBUI_HASH_OLD:-}" ]]; then
    replace_hash "SMARTDNS_WEBUI_HASH" "${SMARTDNS_WEBUI_HASH_OLD}" "${NEW_WEBUI_HASH}"
elif [[ -n "${SMARTDNS_WEBUI_MIRROR_HASH_OLD:-}" ]]; then
    replace_hash "MIRROR_HASH" "${SMARTDNS_WEBUI_MIRROR_HASH_OLD}" "${NEW_WEBUI_HASH}"
else
    echo "ERROR: neither SMARTDNS_WEBUI_HASH nor MIRROR_HASH is set in ${MAKEFILE}" >&2
    exit 1
fi

echo "==> Done updating hashes in ${MAKEFILE}"

# Output new hashes for downstream use
echo "NEW_SMARTDNS_HASH=${NEW_SMARTDNS_HASH}"
echo "NEW_WEBUI_HASH=${NEW_WEBUI_HASH}"
