#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/powerlevel10k.sh"

readonly __POWERLEVEL10K_SHELL_MODULE_ID="term/power-level-10k"

##
# __install_powerlevel10k_state <install_dir> <force>
#
# Persists the selected Powerlevel10k installation unless conflicting or
# invalid state exists without force.
#
# Parameters:
#   install_dir    Valid absolute Powerlevel10k installation directory.
#   force          1 to replace conflicting or invalid state, or 0 otherwise.
#
# Returns:
#   1 when existing state cannot be replaced safely or persistence fails.
#
__install_powerlevel10k_state() {
    local install_dir="$1"
    local force="$2"
    local persisted_dir

    if [[ ! -e "$__POWERLEVEL10K_STATE_FILE" ]] &&
        [[ ! -L "$__POWERLEVEL10K_STATE_FILE" ]]; then
        write_powerlevel10k_state "$install_dir" || return $?
        log_info "Configured Powerlevel10k installation directory: $install_dir"

        return 0
    fi

    if persisted_dir="$(read_powerlevel10k_state)"; then
        if [[ "$persisted_dir" == "$install_dir" ]]; then
            log_info "Powerlevel10k installation state is already configured: $install_dir"

            return 0
        fi

        if (( ! force )); then
            log_error "Powerlevel10k state already points to a different installation: $persisted_dir"
            log_error "Use --force to replace it with: $install_dir"

            return 1
        fi

        log_warn "Replacing Powerlevel10k installation state: $persisted_dir -> $install_dir"
    elif (( ! force )); then
        log_error "Powerlevel10k state is invalid or unreadable: $__POWERLEVEL10K_STATE_FILE"
        log_error "Use --force to replace it"

        return 1
    else
        log_warn "Replacing invalid Powerlevel10k installation state: $__POWERLEVEL10K_STATE_FILE"
    fi

    write_powerlevel10k_state "$install_dir" || return $?
    log_info "Configured Powerlevel10k installation directory: $install_dir"
}

main() {
    local install_dir
    local selected
    local force=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    if ! install_dir="$(resolve_powerlevel10k_install_dir)"; then
        log_error "POWERLEVEL10K_INSTALL_DIR must be an absolute path without line breaks"

        return 1
    fi

    if ! powerlevel10k_installation_valid "$install_dir"; then
        log_error "Powerlevel10k theme is missing or unreadable: $install_dir/powerlevel10k.zsh-theme"

        return 1
    fi

    while true; do
        printf 'Current Powerlevel10k Status:\n-----------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Powerlevel10k Configuration:\n----------------------------' \
                "Install Powerlevel10k state file" \
                "Enable Zsh integration" \
                "Activate Zsh loader"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __install_powerlevel10k_state \
                    "$install_dir" "$force" || return $?
                ;;
            2)
                install_shell_integration \
                    zsh "$__POWERLEVEL10K_SHELL_MODULE_ID" "$force" || return $?
                ;;
            3)
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
