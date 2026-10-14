#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__set_inotify_limit() {
    local current_limit
    local new_limit

    if ! current_limit="$(jetbrains_inotify_state)"; then
        current_limit="$__JETBRAINS_DEFAULT_WATCHES"
    fi

    if ! new_limit="$(ask_text "How many inotify watches should be allowed?" "$current_limit")"; then
        log_warn "Fail to obtain user input, prevent writing the sysctl file"

        return 0
    fi

    if ! jetbrains_valid_watches "$new_limit"; then
        log_error "The limit must be a positive integer up to $__JETBRAINS_MAX_WATCHES: $new_limit"

        return 1
    fi

    write_jetbrains_inotify_limit "$new_limit"
}

main() {
    local selected
    local -a options=()

    while true; do
        show_status $'Current JetBrains Status:\n-----------------------' \
            bash "$CONFIG_MODULE_DIR/status.sh" || return $?

        options=(
            "Set inotify watches limit (default $__JETBRAINS_DEFAULT_WATCHES)"
            "Remove inotify watches limit"
        )

        if ! selected="$(
            choose_option $'JetBrains Configuration:\n------------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        # A failed action is already logged; keep the menu open.
        case "$selected" in
            1)
                __set_inotify_limit || true
                ;;
            2)
                remove_jetbrains_inotify_limit || true
                ;;
            X)
                return 0
                ;;
        esac

        pause_prompt
    done
}

main "$@"
