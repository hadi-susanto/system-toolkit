#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/apt-fast.sh"

main() {
    local selected

    while true; do
        printf 'Current apt-fast Completion Status:\n-----------------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'apt-fast Completion Installation:\n---------------------------------' \
                "Install Bash completion from vendor source" \
                "Install Zsh completion from vendor source" \
                "Install Bash completion from local file" \
                "Install Zsh completion from local file" \
                "Uninstall Bash completion" \
                "Uninstall Zsh completion"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                install_vendor_completion bash || return $?
                ;;
            2)
                install_vendor_completion zsh || return $?
                ;;
            3)
                install_local_completion bash || return $?
                ;;
            4)
                install_local_completion zsh || return $?
                ;;
            5)
                uninstall_completion bash || return $?
                ;;
            6)
                uninstall_completion zsh || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
