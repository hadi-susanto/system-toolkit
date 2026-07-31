#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/sdkman.sh"

readonly __SDKMAN_SHELL_MODULE_ID="dev/sdkman"

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
            printf '%s[active]%s\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[inactive]%s\n' "$COLOR_RED" "$COLOR_RESET"
            ;;
        2)
            printf '%s[shell not installed]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
        *)
            log_error "Unable to determine $shell loader status"
            printf '%s[unknown]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
    esac
}

__print_module_status() {
    local shell="$1"
    local status=0

    if __run_shell_status "$shell" "$__SDKMAN_SHELL_MODULE_ID"; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            printf '%s[installed]%s\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[not installed]%s\n' "$COLOR_RED" "$COLOR_RESET"
            ;;
        *)
            log_error "Unable to determine $shell SDKMAN! module status"
            printf '%s[unknown]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
    esac
}

__print_state_status() {
    local install_dir

    if [[ ! -e "$__SDKMAN_STATE_FILE" ]] && [[ ! -L "$__SDKMAN_STATE_FILE" ]]; then
        printf '%s[missing]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$__SDKMAN_STATE_FILE"

        return 0
    fi

    if ! install_dir="$(read_sdkman_state)"; then
        printf '%s[invalid]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$__SDKMAN_STATE_FILE"

        return 0
    fi

    if ! sdkman_installation_valid "$install_dir"; then
        printf '%s[SDKMAN! init unavailable]%s %s\n' \
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
    printf '  Bash: '
    if ! __print_module_status bash; then
        failed=1
    fi

    printf '  Zsh : '
    if ! __print_module_status zsh; then
        failed=1
    fi

    printf 'Loader Status:\n'
    printf '  Bash: '
    if ! __print_loader_status bash; then
        failed=1
    fi

    printf '  Zsh : '
    if ! __print_loader_status zsh; then
        failed=1
    fi

    return "$failed"
}

main "$@"
