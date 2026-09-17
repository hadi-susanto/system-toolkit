#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __STARSHIP_SHELL_MODULE_ID="term/starship"

__configure_starship_newline() {
    local state="$1"
    local confirmation_status
    
    if ! command -v starship >/dev/null 2>&1; then
        log_error "Starship is required before its configuration can be installed"

        return 1
    fi

    printf 'The following Starship configuration changes will be applied:\n  add_newline = %s\n' \
        "$state" >&2

    if confirm_action "Apply these changes?"; then
        :
    else
        confirmation_status=$?

        if (( confirmation_status == 1 )); then
            log_info "Starship configuration changes were cancelled"

            return 0
        fi

        return "$confirmation_status"
    fi

    if ! starship config add_newline "$state"; then
        log_error "Failed to update the Starship configuration"

        return 1
    fi

    log_info "Updated Starship configuration: add_newline = $state"
}

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
        printf 'Current Starship Status:\n------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        # Dynamically change the option based on integration status(es)
        options=()
        if run_shell_status bash "$__STARSHIP_SHELL_MODULE_ID"; then
            bash_integration_installed=1
            options+=("Disable Bash integration")
        else
            bash_integration_installed=0
            options+=("Enable Bash integration")
        fi
        if run_shell_status zsh "$__STARSHIP_SHELL_MODULE_ID"; then
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
        options+=("Set add_newline = false (when shell integration is installed)." "Set add_newline = true (when shell integration is removed).")

        if ! selected="$(
            choose_option $'Starship Configuration:\n-----------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                if (( bash_integration_installed )); then
                    uninstall_shell_integration \
                        bash "$__STARSHIP_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        bash "$__STARSHIP_SHELL_MODULE_ID" "$force" || return $?
                fi
                ;;
            2)
                if (( zsh_integration_installed )); then
                    uninstall_shell_integration \
                        zsh "$__STARSHIP_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        zsh "$__STARSHIP_SHELL_MODULE_ID" "$force" || return $?
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
            5)
                __configure_starship_newline "false" || return $?
                ;;
            6)
                __configure_starship_newline "true" || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
