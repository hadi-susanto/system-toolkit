#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/checks.sh"
source "$CONFIG_MODULE_DIR/lib/plymouth.sh"

main() {
    local state

    if plymouth_state; then
        state=0
    else
        state=$?
    fi

    case "$state" in
        0 | 1)
            return "$CONFIG_CHECK_PROCEED"
            ;;
        2)
            log_error "GRUB configuration file is unavailable: $__PLYMOUTH_GRUB_FILE"

            return "$CONFIG_CHECK_BLOCK"
            ;;
        3)
            log_error "GRUB_CMDLINE_LINUX_DEFAULT has a custom or inconsistent value"

            return "$CONFIG_CHECK_BLOCK"
            ;;
    esac
}

main "$@"
