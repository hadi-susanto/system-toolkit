#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

main() {
    local auto_update_state

    printf 'Auto-Update Status:\n'
    printf '  • auto-update: '
    if auto_update_state="$(read_junie_auto_update_state)"; then
        if [[ -n "$auto_update_state" ]]; then
            printf '%s\n' "$auto_update_state"
        else
            printf '%s[-] not set (defaults to true)%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
        fi
    else
        printf '%s[?] unknown%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

        return 1
    fi
}

main "$@"
