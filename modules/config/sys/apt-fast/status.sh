#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib/apt-fast.sh"

__print_completion_status() {
    local shell="$1"
    local target="$2"

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        printf '%s[✗]%s not installed\n' "$COLOR_RED" "$COLOR_RESET"

        return 0
    fi

    if [[ ! -f "$target" ]] || [[ -L "$target" ]]; then
        printf '%s[?]%s invalid %s target: %s\n' \
            "$COLOR_YELLOW" "$COLOR_RESET" "$shell" "$target"

        return 1
    fi

    printf '%s[✓]%s installed\n' "$COLOR_GREEN" "$COLOR_RESET"
}

main() {
    local failed=0

    printf 'apt-fast Executable: '
    if command -v apt-fast >/dev/null 2>&1; then
        printf '%s[✓]%s installed\n' "$COLOR_GREEN" "$COLOR_RESET"
    else
        printf '%s[✗]%s not installed\n' "$COLOR_RED" "$COLOR_RESET"
    fi

    printf 'Bash Completion    : '
    if ! __print_completion_status bash "$__APT_FAST_BASH_TARGET"; then
        failed=1
    fi

    printf 'Zsh Completion     : '
    if ! __print_completion_status zsh "$__APT_FAST_ZSH_TARGET"; then
        failed=1
    fi

    return "$failed"
}

main "$@"
