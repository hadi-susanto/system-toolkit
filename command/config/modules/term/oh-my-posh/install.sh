#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$COMMON_LIB/runner.sh"

readonly __OH_MY_POSH_SHELL_MODULE_ID="term/oh-my-posh"

__install_shell_integration() {
    local shell="$1"
    local force="$2"
    local -a force_args=()

    if [[ "$force" == "true" ]]; then
        force_args+=(--force)
    fi

    if ! run_syskit_bin \
        "syskit-$shell" install "${force_args[@]}" \
        "$__OH_MY_POSH_SHELL_MODULE_ID"; then
        log_error "Failed to install Oh My Posh integration for $shell"

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

main() {
    local selected

    while true; do
        printf 'Current Oh My Posh Status:\n--------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Oh My Posh Configuration:\n--------------------------' \
                "Enable Bash integration" \
                "Enable Zsh integration" \
                "Install Bash Loader" \
                "Install Zsh Loader"
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
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
