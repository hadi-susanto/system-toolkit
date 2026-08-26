#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __OH_MY_POSH_SHELL_MODULE_ID="term/oh-my-posh"

main() {
    local selected
    local force=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    while true; do
        printf 'Current Oh My Posh Status:\n--------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Oh My Posh Configuration:\n--------------------------' \
                "Enable Bash integration" \
                "Enable Zsh integration" \
                "Install Bash Loader" \
                "Install Zsh Loader"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                install_shell_integration \
                    bash "$__OH_MY_POSH_SHELL_MODULE_ID" "$force" || return $?
                ;;
            2)
                install_shell_integration \
                    zsh "$__OH_MY_POSH_SHELL_MODULE_ID" "$force" || return $?
                ;;
            3)
                install_shell_loader bash "$force" || return $?
                ;;
            4)
                install_shell_loader zsh "$force" || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
