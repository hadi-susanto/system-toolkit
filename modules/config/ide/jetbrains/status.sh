#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__print_configured_status() {
    local value
    local state=0

    value="$(jetbrains_inotify_state)" || state=$?

    case "$state" in
        0)
            printf '%s[configured]%s %s (%s)\n' \
                "$COLOR_GREEN" "$COLOR_RESET" "$value" "$__JETBRAINS_SYSCTL_FILE"
            ;;
        1)
            printf '%s[not-configured]%s\n' "$COLOR_CYAN" "$COLOR_RESET"
            ;;
        *)
            printf '%s[invalid]%s %s\n' \
                "$COLOR_RED" "$COLOR_RESET" "$__JETBRAINS_SYSCTL_FILE"
            ;;
    esac
}

main() {
    local running

    printf 'Inotify Watches:\n'
    printf '  Config file  : '
    __print_configured_status

    printf '  Running limit: '
    if running="$(jetbrains_running_watches)"; then
        printf '%s\n' "$running"
    else
        printf '%s[unknown]%s\n' "$COLOR_RED" "$COLOR_RESET"

        return 1
    fi
}

main "$@"
