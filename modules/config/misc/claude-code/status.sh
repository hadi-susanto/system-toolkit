#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

readonly __CLAUDE_CODE_SHELL_MODULE_ID="misc/claude-code"

main() {
    local failed=0
    local auto_updater_status

    printf 'Auto-Update Status:\n'
    printf '  • autoUpdaterStatus: '
    if auto_updater_status="$(read_claude_code_auto_updater_status)"; then
        if [[ -n "$auto_updater_status" ]]; then
            printf '%s\n' "$auto_updater_status"
        else
            printf '%s[-] not set (defaults to enabled)%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
        fi
    else
        printf '%s[?] unknown%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
        failed=1
    fi

    printf 'Integration Status:\n'
    printf '  • Bash: '
    if ! print_module_status bash "$__CLAUDE_CODE_SHELL_MODULE_ID"; then
        failed=1
    fi

    printf '  • Zsh : '
    if ! print_module_status zsh "$__CLAUDE_CODE_SHELL_MODULE_ID"; then
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
