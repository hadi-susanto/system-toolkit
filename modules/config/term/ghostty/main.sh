#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/ghostty.sh"

main() {
    local selected
    local -a options=()
    local ghostty_loader_installed=0
    local ghostty_config_installed=0

    while true; do
        printf 'Current Ghostty Status:\n-----------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        # Dynamically change the option based on integration status(es)
        options=()
        if ghostty_loader_state; then
            ghostty_loader_installed=1
            options+=("Remove SysKit loader from ghostty file configuration")
        else
            ghostty_loader_installed=0
            options+=("Install SysKit loader into ghostty file configuration")
        fi
        if [[ -e "$__GHOSTTY_CONFIG_DIR/$__GHOSTTY_PAYLOAD_FILE" ]]; then
            ghostty_config_installed=1
            options+=("Remove $__GHOSTTY_PAYLOAD_FILE from $__GHOSTTY_CONFIG_DIR")
        else
            ghostty_config_installed=0
            options+=("Install $__GHOSTTY_PAYLOAD_FILE into $__GHOSTTY_CONFIG_DIR")
        fi

        if ! selected="$(
            choose_option $'Ghostty Configuration:\n----------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                if (( ghostty_loader_installed )); then
                    uninstall_ghostty_loader
                else
                    install_ghostty_loader
                fi
                ;;
            2)
                if (( ghostty_config_installed )); then
                    uninstall_ghostty_file_config
                else
                    install_ghostty_file_config
                fi
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
