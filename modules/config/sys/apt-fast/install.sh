#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/apt-fast.sh"

__resolve_completion() {
    local shell="$1"
    local source_type="$2"
    local source_name="$3"
    local target_name="$4"
    local -n source_ref="$source_name"
    local -n target_ref="$target_name"

    case "$shell:$source_type" in
        bash:local)
            source_ref="$CONFIG_MODULE_PAYLOAD/$__APT_FAST_BASH_PAYLOAD"
            target_ref="$__APT_FAST_BASH_TARGET"
            ;;
        bash:vendor)
            source_ref="$__APT_FAST_BASH_VENDOR_URL"
            target_ref="$__APT_FAST_BASH_TARGET"
            ;;
        zsh:local)
            source_ref="$CONFIG_MODULE_PAYLOAD/$__APT_FAST_ZSH_PAYLOAD"
            target_ref="$__APT_FAST_ZSH_TARGET"
            ;;
        zsh:vendor)
            source_ref="$__APT_FAST_ZSH_VENDOR_URL"
            target_ref="$__APT_FAST_ZSH_TARGET"
            ;;
        *)
            log_error "Unsupported apt-fast completion selection: $shell/$source_type"

            return 1
            ;;
    esac
}

__validate_completion_target() {
    local shell="$1"
    local target="$2"

    if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
        log_error "apt-fast $shell completion target is a directory: $target"

        return 1
    fi

    if [[ -L "$target" ]]; then
        log_error "apt-fast $shell completion target is a symbolic link: $target"

        return 1
    fi

    if [[ -e "$target" ]] && [[ ! -f "$target" ]]; then
        log_error "apt-fast $shell completion target is not a regular file: $target"

        return 1
    fi

    if [[ ! -e "$target" ]]; then
        return 0
    fi

    if [[ "${CONFIG_FORCE:-false}" != "true" ]]; then
        log_error "apt-fast $shell completion already exists; use --force to overwrite: $target"

        return 1
    fi

    log_warn "Overwriting apt-fast $shell completion: $target"
}

__install_local_completion() {
    local shell="$1"
    local source
    local target

    __resolve_completion "$shell" local source target || return $?

    if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
        log_error "apt-fast $shell completion payload is unavailable: $source"

        return 1
    fi

    __validate_completion_target "$shell" "$target" || return $?

    if ! sudo install -Dm0644 -- "$source" "$target"; then
        log_error "Failed to install local apt-fast $shell completion: $target"

        return 1
    fi

    log_info "Installed local apt-fast $shell completion: $target"
}

__install_vendor_completion() {
    local shell="$1"
    local source
    local target
    local temporary_file

    __resolve_completion "$shell" vendor source target || return $?
    __validate_completion_target "$shell" "$target" || return $?

    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is required to install apt-fast completions from the vendor source"

        return 1
    fi

    if ! temporary_file="$(mktemp)"; then
        log_error "Failed to create a temporary apt-fast completion file"

        return 1
    fi

    if ! curl -fsSL -o "$temporary_file" -- "$source"; then
        log_error "Failed to download apt-fast $shell completion: $source"

        if ! rm -f -- "$temporary_file"; then
            log_warn "Failed to remove temporary apt-fast completion file: $temporary_file"
        fi

        return 1
    fi

    if [[ ! -s "$temporary_file" ]]; then
        log_error "Downloaded apt-fast $shell completion is empty: $source"

        if ! rm -f -- "$temporary_file"; then
            log_warn "Failed to remove temporary apt-fast completion file: $temporary_file"
        fi

        return 1
    fi

    if ! sudo install -Dm0644 -- "$temporary_file" "$target"; then
        log_error "Failed to install vendor apt-fast $shell completion: $target"

        if ! rm -f -- "$temporary_file"; then
            log_warn "Failed to remove temporary apt-fast completion file: $temporary_file"
        fi

        return 1
    fi

    if ! rm -f -- "$temporary_file"; then
        log_warn "Failed to remove temporary apt-fast completion file: $temporary_file"
    fi

    log_info "Installed vendor apt-fast $shell completion: $target"
}

main() {
    local selected

    while true; do
        printf 'Current apt-fast Completion Status:\n-----------------------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'apt-fast Completion Installation:\n---------------------------------' \
                "Install Bash completion from vendor source" \
                "Install Zsh completion from vendor source" \
                "Install Bash completion from local file" \
                "Install Zsh completion from local file"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __install_vendor_completion bash || return $?
                ;;
            2)
                __install_vendor_completion zsh || return $?
                ;;
            3)
                __install_local_completion bash || return $?
                ;;
            4)
                __install_local_completion zsh || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
