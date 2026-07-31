#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __STARSHIP_SHELL_MODULE_ID="term/starship"

__install_shell_integration() {
    local shell="$1"
    local force="$2"
    local -a force_args=()

    if [[ "$force" == "true" ]]; then
        force_args+=(--force)
    fi

    if ! run_syskit_bin \
        "syskit-$shell" install "${force_args[@]}" \
        "$__STARSHIP_SHELL_MODULE_ID"; then
        log_error "Failed to install Starship integration for $shell"

        return 1
    fi
}

__install_shell_loader() {
    local shell="$1"
    local force="$2"
    local -a force_args=()

    if [[ "$force" == "true" ]]; then
        force_args+=(--force)
    fi

    if ! run_syskit_bin "syskit-$shell" activate "${force_args[@]}"; then
        log_error "Failed to install the SysKit $shell loader"

        return 1
    fi
}

__install_starship_configuration() {
    local confirmation_status

    printf '%s\n' \
        'The following Starship configuration changes will be applied:' \
        '  add_newline = false' \
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

    if ! starship config add_newline false; then
        log_error "Failed to update the Starship configuration"

        return 1
    fi

    log_info "Updated Starship configuration: add_newline = false"
}

main() {
    local selected

    while true; do
        printf 'Current Starship Status:\n------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Starship Configuration:\n-----------------------' \
                "Enable Bash integration" \
                "Enable Zsh integration" \
                "Install Bash Loader" \
                "Install Zsh Loader" \
                "Install pre-defined configuration"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __install_shell_integration \
                    bash "${CONFIG_FORCE:-false}" || return $?
                ;;
            2)
                __install_shell_integration \
                    zsh "${CONFIG_FORCE:-false}" || return $?
                ;;
            3)
                __install_shell_loader \
                    bash "${CONFIG_FORCE:-false}" || return $?
                ;;
            4)
                __install_shell_loader \
                    zsh "${CONFIG_FORCE:-false}" || return $?
                ;;
            5)
                __install_starship_configuration || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
