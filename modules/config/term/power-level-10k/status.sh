#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/powerlevel10k.sh"

readonly __POWERLEVEL10K_SHELL_MODULE_ID="term/power-level-10k"

__print_state_status() {
    local install_dir

    if [[ ! -e "$__POWERLEVEL10K_STATE_FILE" ]] &&
        [[ ! -L "$__POWERLEVEL10K_STATE_FILE" ]]; then
        printf '%s[missing]%s %s\n' \
            "$COLOR_RED" "$COLOR_RESET" "$__POWERLEVEL10K_STATE_FILE"

        return 0
    fi

    if ! install_dir="$(read_powerlevel10k_state)"; then
        printf '%s[invalid]%s %s\n' \
            "$COLOR_RED" "$COLOR_RESET" "$__POWERLEVEL10K_STATE_FILE"

        return 0
    fi

    if ! powerlevel10k_installation_valid "$install_dir"; then
        printf '%s[theme unavailable]%s %s\n' \
            "$COLOR_RED" "$COLOR_RESET" "$install_dir"

        return 0
    fi

    printf '%s[configured]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$install_dir"
}

main() {
    local failed=0

    printf 'Installation State:\n'
    printf '  Directory: '
    __print_state_status

    printf 'Integration Status:\n'
    printf '  Zsh: '
    if ! print_module_status zsh "$__POWERLEVEL10K_SHELL_MODULE_ID"; then
        failed=1
    fi

    printf 'Loader Status:\n'
    printf '  Zsh: '
    if ! print_loader_status zsh; then
        failed=1
    fi

    return "$failed"
}

main "$@"
