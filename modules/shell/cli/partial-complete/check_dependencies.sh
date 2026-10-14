#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/interface_loader.sh"

main() {
    local shell="${1:-}"

    if [[ "$shell" != "bash" ]]; then
        log_error "Partial completion supports only Bash: ${shell:-<missing>}"

        return 1
    fi

    load_shell_interface "$shell" "module_installed" || return $?

    if module_installed "cli/partial-cd"; then
        log_error "Partial CD integration is already installed for this shell; use --force to install Partial Complete anyway"

        return 1
    fi
}

main "$@"
