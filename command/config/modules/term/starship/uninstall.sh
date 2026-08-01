#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __STARSHIP_SHELL_MODULE_ID="term/starship"

__uninstall_starship_configuration() {
    local confirmation_status

    printf '%s\n' \
        'The following Starship configuration changes will be applied:' \
        '  add_newline = true' \
        '' >&2

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

    if ! command -v starship >/dev/null 2>&1; then
        log_error "Starship is required to restore add_newline = true"

        return 1
    fi

    if ! starship config add_newline true; then
        log_error "Failed to update the Starship configuration"

        return 1
    fi

    log_info "Updated Starship configuration: add_newline = true"
}

main() {
    local selected
    local force=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    while true; do
        printf 'Current Starship Status:\n------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Starship Uninstallation:\n------------------------' \
                "Disable Bash integration" \
                "Disable Zsh integration" \
                "Uninstall Bash Loader" \
                "Uninstall Zsh Loader" \
                "Uninstall pre-defined configuration"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                uninstall_shell_integration \
                    bash "$__STARSHIP_SHELL_MODULE_ID" "$force" || return $?
                ;;
            2)
                uninstall_shell_integration \
                    zsh "$__STARSHIP_SHELL_MODULE_ID" "$force" || return $?
                ;;
            3)
                uninstall_shell_loader bash "$force" || return $?
                ;;
            4)
                uninstall_shell_loader zsh "$force" || return $?
                ;;
            5)
                __uninstall_starship_configuration || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
