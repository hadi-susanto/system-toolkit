#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/apt-fast.sh"

__uninstall_completion() {
    local shell="$1"
    local target

    case "$shell" in
        bash)
            target="$__APT_FAST_BASH_TARGET"
            ;;
        zsh)
            target="$__APT_FAST_ZSH_TARGET"
            ;;
        *)
            log_error "Unsupported apt-fast completion shell: $shell"

            return 1
            ;;
    esac

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        log_warn "apt-fast $shell completion is not installed: $target"

        return 0
    fi

    if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
        log_error "apt-fast $shell completion target is a directory: $target"

        return 1
    fi

    if ! sudo rm -f -- "$target"; then
        log_error "Failed to uninstall apt-fast $shell completion: $target"

        return 1
    fi

    log_info "Uninstalled apt-fast $shell completion: $target"
}

main() {
    local selected

    while true; do
        printf 'Current apt-fast Completion Status:\n-----------------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'apt-fast Completion Uninstallation:\n-----------------------------------' \
                "Uninstall Bash completion" \
                "Uninstall Zsh completion"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __uninstall_completion bash || return $?
                ;;
            2)
                __uninstall_completion zsh || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
