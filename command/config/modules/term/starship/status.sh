#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/runner.sh"

readonly __STARSHIP_SHELL_MODULE_ID="term/starship"

main() {
    local failed=0

    printf 'Integration Status:\n'
    printf '  • Bash: '
    if ! print_module_status bash "$__STARSHIP_SHELL_MODULE_ID"; then
        failed=1
    fi

    printf '  • Zsh : '
    if ! print_module_status zsh "$__STARSHIP_SHELL_MODULE_ID"; then
        failed=1
    fi

    printf 'Loader Status:\n'
    printf '  • Bash: '
    if ! print_loader_status bash; then
        failed=1
    fi

    printf '  • Zsh : '
    if ! print_loader_status zsh; then
        failed=1
    fi

    return "$failed"
}

main "$@"
