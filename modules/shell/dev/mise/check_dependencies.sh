#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/interface_loader.sh"

main() {
    local shell="${1:-}"

    if ! command -v mise >/dev/null 2>&1; then
        log_error "Mise is required before its shell integration can be installed"

        return 1
    fi

    load_shell_interface "$shell" "module_installed" || return $?

    if module_installed "dev/sdkman"; then
        log_error "SDKMAN! integration is already installed for this shell; use --force to install Mise anyway"

        return 1
    fi
}

main "$@"
