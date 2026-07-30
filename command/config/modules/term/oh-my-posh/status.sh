#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/runner.sh"

readonly __OH_MY_POSH_SHELL_MODULE_ID="term/oh-my-posh"

__run_shell_status() {
    local shell="$1"
    local selector="$2"

    run_syskit_bin "syskit-$shell" status "$selector" >/dev/null 2>&1
}

__print_loader_status() {
    local shell="$1"
    local status=0

    if __run_shell_status "$shell" loader; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            printf '%s[✓]%s active\n' "${COLOR_GREEN}" "${COLOR_RESET}"
            ;;
        1)
            printf '%s[✗]%s inactive\n' "${COLOR_RED}" "${COLOR_RESET}"
            ;;
        2)
            printf '%s[⚠]%s shell not installed\n' "${COLOR_YELLOW}" "${COLOR_RESET}"
            ;;
        *)
            log_error "Unable to determine $shell loader status"
            printf '%s[?]%s unknown\n' "${COLOR_YELLOW}" "${COLOR_RESET}"

            return 1
            ;;
    esac
}

__print_module_status() {
    local shell="$1"
    local status=0

    if __run_shell_status "$shell" "$__OH_MY_POSH_SHELL_MODULE_ID"; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            printf '%s[✓]%s installed\n' "${COLOR_GREEN}" "${COLOR_RESET}"
            ;;
        1)
            printf '%s[✗]%s not installed\n' "${COLOR_RED}" "${COLOR_RESET}"
            ;;
        *)
            log_error "Unable to determine $shell Oh My Posh module status"
            printf '%s[?]%s unknown\n' "${COLOR_YELLOW}" "${COLOR_RESET}"

            return 1
            ;;
    esac
}

main() {
    local failed=0

    printf 'Integration Status:\n'
    printf '  • Bash: '
    if ! __print_module_status bash; then
        failed=1
    fi

    printf '  • Zsh : '
    if ! __print_module_status zsh; then
        failed=1
    fi

    printf 'Loader Status:\n'
    printf '  • Bash: '
    if ! __print_loader_status bash; then
        failed=1
    fi

    printf '  • Zsh : '
    if ! __print_loader_status zsh; then
        failed=1
    fi

    return "$failed"
}

main "$@"
