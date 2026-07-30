#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __OH_MY_POSH_SHELL_MODULE_ID="term/oh-my-posh"

__uninstall_shell_integration() {
    local shell="$1"

    if ! run_syskit_bin \
        "syskit-$shell" uninstall "$__OH_MY_POSH_SHELL_MODULE_ID"; then
        log_error "Failed to uninstall Oh My Posh integration for $shell"

        return 1
    fi
}

__uninstall_shell_loader() {
    local shell="$1"

    if ! run_syskit_bin "syskit-$shell" deactivate; then
        log_error "Failed to uninstall the SysKit $shell loader"

        return 1
    fi
}

main() {
    local selected

    while true; do
        printf 'Current Oh My Posh Status:\n--------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Oh My Posh Uninstallation:\n-----------------------------' \
                "Disable Bash integration" \
                "Disable Zsh integration" \
                "Uninstall Bash Loader" \
                "Uninstall Zsh Loader"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __uninstall_shell_integration bash || return $?
                ;;
            2)
                __uninstall_shell_integration zsh || return $?
                ;;
            3)
                __uninstall_shell_loader bash || return $?
                ;;
            4)
                __uninstall_shell_loader zsh || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
