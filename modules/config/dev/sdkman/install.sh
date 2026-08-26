#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"
source "$CONFIG_MODULE_DIR/lib/sdkman.sh"

readonly __SDKMAN_SHELL_MODULE_ID="dev/sdkman"

##
# __install_sdkman_state <install_dir> <force>
#
# Persists the selected SDKMAN! installation unless conflicting or invalid
# state exists without force.
#
# Parameters:
#   install_dir    Valid absolute SDKMAN! installation directory.
#   force          1 to replace conflicting or invalid state, or 0 otherwise.
#
# Returns:
#   1 when existing state cannot be replaced safely or persistence fails.
#
__install_sdkman_state() {
    local install_dir="$1"
    local force="$2"
    local persisted_dir

    if [[ ! -e "$__SDKMAN_STATE_FILE" ]] && [[ ! -L "$__SDKMAN_STATE_FILE" ]]; then
        write_sdkman_state "$install_dir" || return $?
        log_info "Configured SDKMAN! installation directory: $install_dir"

        return 0
    fi

    if persisted_dir="$(read_sdkman_state)"; then
        if [[ "$persisted_dir" == "$install_dir" ]]; then
            log_info "SDKMAN! installation state is already configured: $install_dir"

            return 0
        fi

        if (( ! force )); then
            log_error "SDKMAN! state already points to a different installation: $persisted_dir"
            log_error "Use --force to replace it with: $install_dir"

            return 1
        fi

        log_warn "Replacing SDKMAN! installation state: $persisted_dir -> $install_dir"
    elif (( ! force )); then
        log_error "SDKMAN! state is invalid or unreadable: $__SDKMAN_STATE_FILE"
        log_error "Use --force to replace it"

        return 1
    else
        log_warn "Replacing invalid SDKMAN! installation state: $__SDKMAN_STATE_FILE"
    fi

    write_sdkman_state "$install_dir" || return $?
    log_info "Configured SDKMAN! installation directory: $install_dir"
}

main() {
    local install_dir
    local selected
    local force=0

    if [[ "${CONFIG_FORCE:-false}" == "true" ]]; then
        force=1
    fi

    if ! install_dir="$(resolve_sdkman_install_dir)"; then
        log_error "SDKMAN_DIR must be an absolute path without line breaks"

        return 1
    fi

    if ! sdkman_installation_valid "$install_dir"; then
        log_error "SDKMAN! initialization is missing or unreadable: $install_dir/bin/sdkman-init.sh"

        return 1
    fi

    while true; do
        printf 'Current SDKMAN! Status:\n-----------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'SDKMAN! Configuration:\n----------------------' \
                "Install SDKMAN! state file" \
                "Enable Bash integration" \
                "Enable Zsh integration" \
                "Activate Bash loader" \
                "Activate Zsh loader"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __install_sdkman_state \
                    "$install_dir" "$force" || return $?
                ;;
            2)
                install_shell_integration \
                    bash "$__SDKMAN_SHELL_MODULE_ID" "$force" || return $?
                ;;
            3)
                install_shell_integration \
                    zsh "$__SDKMAN_SHELL_MODULE_ID" "$force" || return $?
                ;;
            4)
                install_shell_loader bash "$force" || return $?
                ;;
            5)
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
