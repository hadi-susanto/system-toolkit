#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/interface_loader.sh"

main() {
    local shell="${1:-}"

    if ! command -v oh-my-posh >/dev/null 2>&1; then
        log_error "Oh My Posh is required before its shell integration can be installed"

        return 1
    fi

    load_shell_interface "$shell" "module_installed" || return $?

    if module_installed "term/starship"; then
        log_error "Starship integration is already installed for this shell; use --force to install Oh My Posh anyway"

        return 1
    fi

    if module_installed "term/power-level-10k"; then
        log_error "Powerlevel10k integration is already installed for this shell; use --force to install Oh My Posh anyway"

        return 1
    fi
}

main "$@"
