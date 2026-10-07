#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

readonly __CLAUDE_CODE_SHELL_MODULE_ID="misc/claude-code"

__configure_claude_code_auto_updater() {
    local status="$1"
    local confirmation_status

    printf 'The following Claude Code settings changes will be applied:\n  autoUpdaterStatus = %s\n' \
        "$status" >&2

    if confirm_action "Apply these changes?"; then
        :
    else
        confirmation_status=$?

        if (( confirmation_status == 1 )); then
            log_info "Claude Code settings changes were cancelled"

            return 0
        fi

        return "$confirmation_status"
    fi

    if ! write_claude_code_auto_updater_status "$status"; then
        log_error "Failed to update the Claude Code settings"

        return 1
    fi

    log_info "Updated Claude Code settings: autoUpdaterStatus = $status"
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
        printf 'Current Claude Code Status:\n----------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        # Dynamically change the option based on integration status(es)
        options=("Enable Auto Update (autoUpdaterStatus = enabled)" "Disable Auto Update (autoUpdaterStatus = disabled)")
        if run_shell_status bash "$__CLAUDE_CODE_SHELL_MODULE_ID"; then
            bash_integration_installed=1
            options+=("Disable Bash integration")
        else
            bash_integration_installed=0
            options+=("Enable Bash integration")
        fi
        if run_shell_status zsh "$__CLAUDE_CODE_SHELL_MODULE_ID"; then
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
            choose_option $'Claude Code Configuration:\n---------------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __configure_claude_code_auto_updater "enabled" || return $?
                ;;
            2)
                __configure_claude_code_auto_updater "disabled" || return $?
                ;;
            3)
                if (( bash_integration_installed )); then
                    uninstall_shell_integration \
                        bash "$__CLAUDE_CODE_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        bash "$__CLAUDE_CODE_SHELL_MODULE_ID" "$force" || return $?
                fi
                ;;
            4)
                if (( zsh_integration_installed )); then
                    uninstall_shell_integration \
                        zsh "$__CLAUDE_CODE_SHELL_MODULE_ID" "$force" || return $?
                else
                    install_shell_integration \
                        zsh "$__CLAUDE_CODE_SHELL_MODULE_ID" "$force" || return $?
                fi
                ;;
            5)
                if (( bash_loader_installed )); then
                    uninstall_shell_loader bash "$force" || return $?
                else
                    install_shell_loader bash "$force" || return $?
                fi
                ;;
            6)
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
