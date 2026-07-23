#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/__common.sh"

main() {
    if [[ $# -eq 0 ]]; then
        log_error "A shell implementation is required"

        return 1
    fi

    local shell_name="$1"
    local display_name
    shift

    display_name="$(shell_display_name "$shell_name")" || return $?
    validate_no_options install "$@" || {
        bash "$SHELL_LIB/help.sh" "$shell_name" install >&2

        return 1
    }

    printf 'Hello world from the %s shell toolkit: install.\n' "$display_name"
}

main "$@"
