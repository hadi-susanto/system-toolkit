#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/checks.sh"
source "$CONFIG_MODULE_DIR/lib/password-asterisks.sh"

main() {
    local state

    if password_asterisks_state; then
        state=0
    else
        state=$?
    fi

    case "$state" in
        0 | 1)
            return "$CONFIG_CHECK_PROCEED"
            ;;
        2)
            log_error "Linux Mint password-feedback sudoers file is unavailable"

            return "$CONFIG_CHECK_BLOCK"
            ;;
        3)
            log_error "Linux Mint password-feedback sudoers files are inconsistent"

            return "$CONFIG_CHECK_BLOCK"
            ;;
    esac
}

main "$@"
