#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib/plymouth.sh"

main() {
    local state=0

    if plymouth_state; then
        state=0
    else
        state=$?
    fi

    case "$state" in
        0)
            printf 'Plymouth: %s[✓]%s enabled\n' \
                "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf 'Plymouth: %s[✗]%s disabled (verbose boot)\n' \
                "$COLOR_RED" "$COLOR_RESET"
            ;;
        2)
            log_error "GRUB configuration file is unavailable: $__PLYMOUTH_GRUB_FILE"
            printf 'Plymouth: %s[?]%s unavailable\n' \
                "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
        3)
            printf 'Plymouth: %s[?]%s custom GRUB configuration\n' \
                "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
    esac
}

main "$@"
