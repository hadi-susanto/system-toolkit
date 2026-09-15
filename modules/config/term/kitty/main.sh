#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/kitty.sh"

main() {
    local selected
    local -a options=()
    local kitty_loader_installed=0

    while true; do
        printf 'Current Kitty Status:\n-----------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        # Dynamically change the option based on integration status(es)
        options=()
        if kitty_loader_state; then
            kitty_loader_installed=1
            options+=("Remove SysKit loader from kitty file configuration")
        else
            kitty_loader_installed=0
            options+=("Install SysKit loader into kitty file configuration")
        fi
        options+=("Install SysKit Kitty's files into $__KITTY_CONFIG_DIR")
        options+=("Remove SysKit Kitty's files from $__KITTY_CONFIG_DIR")

        if ! selected="$(
            choose_option $'Kitty Configuration:\n----------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                if (( kitty_loader_installed )); then
                    uninstall_kitty_loader
                else
                    install_kitty_loader
                fi
                ;;
            2)
                install_kitty_files
                ;;
            3)
                uninstall_kitty_files
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
