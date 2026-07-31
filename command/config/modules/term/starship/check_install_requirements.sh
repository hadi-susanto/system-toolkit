#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/checks.sh"

main() {
    if ! command -v starship >/dev/null 2>&1; then
        log_error "Starship is required before its configuration can be installed"

        return "$CONFIG_CHECK_BLOCK"
    fi

    return "$CONFIG_CHECK_PROCEED"
}

main "$@"
