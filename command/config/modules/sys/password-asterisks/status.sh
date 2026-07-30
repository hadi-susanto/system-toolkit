#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib/password-asterisks.sh"

main() {
    local state=0

    if password_asterisks_state; then
        state=0
    else
        state=$?
    fi

    case "$state" in
        0)
            printf 'Password Asterisks: %s[✓]%s enabled\n' \
                "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf 'Password Asterisks: %s[✗]%s disabled\n' \
                "$COLOR_RED" "$COLOR_RESET"
            ;;
        2)
            printf 'Password Asterisks: %s[?]%s unavailable\n' \
                "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
        3)
            log_error "Linux Mint password-feedback sudoers files are inconsistent"
            printf 'Password Asterisks: %s[?]%s inconsistent\n' \
                "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
    esac
}

main "$@"
