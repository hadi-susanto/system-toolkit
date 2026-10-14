#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/interface_loader.sh"

main() {
    local shell="${1:-}"

    if [[ "$shell" != "bash" ]]; then
        log_error "Partial directory completion supports only Bash: ${shell:-<missing>}"

        return 1
    fi

    load_shell_interface "$shell" "module_installed" || return $?

    if module_installed "cli/partial-complete"; then
        log_error "Partial Complete integration is already installed for this shell; use --force to install Partial CD anyway"

        return 1
    fi
}

main "$@"
