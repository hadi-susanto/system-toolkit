#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

readonly __MISE_SHELL_MODULE_ID="dev/mise"

__print_data_dir_status() {
    local data_dir

    if [[ ! -e "$__MISE_DATA_DIR_FILE" ]] && [[ ! -L "$__MISE_DATA_DIR_FILE" ]]; then
        printf '%s[not-configured]%s\n' "$COLOR_CYAN" "$COLOR_RESET"

        return 0
    fi

    if ! data_dir="$(read_mise_data_dir_state)"; then
        printf '%s[invalid]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$__MISE_DATA_DIR_FILE"

        return 0
    fi

    if [[ -z "$data_dir" ]]; then
        printf '%s[not-configured]%s (data-dir state exists)\n' \
            "$COLOR_CYAN" "$COLOR_RESET"

        return 0
    fi

    printf '%s[configured]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$data_dir"
}

main() {
    local failed=0

    printf 'Installation State:\n'
    printf '  Override Data Dir: '
    __print_data_dir_status

    printf 'Integration Status:\n'
    printf '  Bash: '
    if ! print_module_status bash "$__MISE_SHELL_MODULE_ID"; then
        failed=1
    fi

    printf '  Zsh : '
    if ! print_module_status zsh "$__MISE_SHELL_MODULE_ID"; then
        failed=1
    fi

    printf 'Loader Status:\n'
    printf '  Bash: '
    if ! print_loader_status bash; then
        failed=1
    fi

    printf '  Zsh : '
    if ! print_loader_status zsh; then
        failed=1
    fi

    return "$failed"
}

main "$@"
