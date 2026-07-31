#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/checks.sh"
source "$CONFIG_MODULE_DIR/lib/powerlevel10k.sh"

main() {
    local install_dir

    if ! install_dir="$(resolve_powerlevel10k_install_dir)"; then
        log_error "POWERLEVEL10K_INSTALL_DIR must be an absolute path without line breaks"

        return "$CONFIG_CHECK_BLOCK"
    fi

    if ! powerlevel10k_installation_valid "$install_dir"; then
        log_error "Powerlevel10k theme is missing or unreadable: $install_dir/powerlevel10k.zsh-theme"

        return "$CONFIG_CHECK_BLOCK"
    fi

    return "$CONFIG_CHECK_PROCEED"
}

main "$@"
