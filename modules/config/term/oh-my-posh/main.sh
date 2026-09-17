#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __OH_MY_POSH_SHELL_MODULE_ID="term/oh-my-posh"

main() {
    local selected
    local force=0
    local -a options=()
    local bash_integration_installed=0
    local zsh_integration_installed=0
    local bash_loader_installed=0
    local zsh_loader_installed=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    while true; do
        printf 'Current Oh My Posh Status:\n--------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        # Dynamically change the option based on integration status(es)
        options=()
        if run_shell_status bash "$__OH_MY_POSH_SHELL_MODULE_ID"; then
            bash_integration_installed=1
            options+=("Disable Bash integration")
        else
            bash_integration_installed=0
            options+=("Enable Bash integration")
        fi
        if run_shell_status zsh "$__OH_MY_POSH_SHELL_MODULE_ID"; then
            zsh_integration_installed=1
            options+=("Disable Zsh integration")
        else
            zsh_integration_installed=0
            options+=("Enable Zsh integration")
        fi
        if run_shell_status bash loader; then
            bash_loader_installed=1
            options+=("Uninstall Bash loader (WARN: this will disable all SysKit Bash integration)")
        else
            bash_loader_installed=0
            options+=("Install Bash loader")
        fi
        if run_shell_status zsh loader; then
            zsh_loader_installed=1
            options+=("Uninstall Zsh loader (WARN: this will disable all SysKit Zsh integration)")
        else
            zsh_loader_installed=0
            options+=("Install Zsh loader")
        fi

        if ! selected="$(
            choose_option $'Oh My Posh Configuration:\n--------------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                if (( bash_integration_installed )); then
                    uninstall_shell_integration \
                        bash "$__OH_MY_POSH_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        bash "$__OH_MY_POSH_SHELL_MODULE_ID" "$force" || return $?
                fi
                ;;
            2)
                if (( zsh_integration_installed )); then
                    uninstall_shell_integration \
                        zsh "$__OH_MY_POSH_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        zsh "$__OH_MY_POSH_SHELL_MODULE_ID" "$force" || return $?
                fi
                ;;
            3)
                if (( bash_loader_installed )); then
                    uninstall_shell_loader bash "$force" || return $?
                else
                    install_shell_loader bash "$force" || return $?
                fi
                ;;
            4)
                if (( zsh_loader_installed )); then
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
