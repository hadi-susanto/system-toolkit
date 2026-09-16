#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/powerlevel10k.sh"

readonly __POWERLEVEL10K_SHELL_MODULE_ID="term/power-level-10k"

__install_powerlevel10k_state() {
    local install_dir

    if ! install_dir="$(resolve_powerlevel10k_install_dir)"; then
        log_error "POWERLEVEL10K_INSTALL_DIR must be an absolute path without line breaks"

        return 1
    fi

    write_powerlevel10k_state "$install_dir" || return $?
    log_info "Configured Powerlevel10k installation directory: $install_dir"
}

main() {
    local selected
    local force=0
    local -a options=()
    local state_installed=0
    local integration_installed=0
    local loader_installed=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi


    while true; do
        printf 'Current Powerlevel10k Status:\n-----------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        # Dynamically change the option based on integration status(es)
        options=()
        if [[ -e "$__POWERLEVEL10K_STATE_FILE" ]]; then
            state_installed=1
            options+=("Remove Powerlevel10k state file (Will break zsh integration when enabled)")
        else
            state_installed=0
            options+=("Install Powerlevel10k state file (Required for zsh integration)")
        fi
        if run_shell_status zsh "$__POWERLEVEL10K_SHELL_MODULE_ID"; then
            integration_installed=1
            options+=("Disable Zsh integration")
        else
            integration_installed=0
            options+=("Enable Zsh integration (Require Powerlevel10k state file)")
        fi
        if run_shell_status zsh loader; then
            loader_installed=1
            options+=("Uninstall Zsh loader (WARN: this will disable all SysKit Zsh integration)")
        else
            loader_installed=0
            options+=("Install Zsh loader")
        fi

        if ! selected="$(
            choose_option $'Powerlevel10k Configuration:\n----------------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                if (( state_installed )); then
                    remove_powerlevel10k_state
                else
                    __install_powerlevel10k_state
                fi
                ;;
            2)
                if (( integration_installed )); then
                    uninstall_shell_integration \
                        zsh "$__POWERLEVEL10K_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        zsh "$__POWERLEVEL10K_SHELL_MODULE_ID" "$force" || return $?
                fi
                ;;
            3)
                if (( loader_installed )); then
                    uninstall_shell_loader zsh "$force" || return $?
                else
                    install_shell_loader zsh "$force" || return $?
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
