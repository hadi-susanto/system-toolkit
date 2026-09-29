if (( ${__SYSKIT_APT_FAST_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_APT_FAST_LIB_LOADED=1

readonly __APT_FAST_BASH_PAYLOAD="bash-autocompletion"
readonly __APT_FAST_ZSH_PAYLOAD="zsh-autocompletion"
readonly __APT_FAST_BASH_VENDOR_URL="https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/bash/apt-fast"
readonly __APT_FAST_ZSH_VENDOR_URL="https://raw.githubusercontent.com/ilikenwf/apt-fast/master/completions/zsh/_apt-fast"
readonly __APT_FAST_BASH_TARGET="/etc/bash_completion.d/apt-fast"
readonly __APT_FAST_ZSH_TARGET="/usr/share/zsh/functions/Completion/Debian/_apt-fast"

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

install_local_completion() {
    local shell="$1"
    local source
    local target

    case "$shell" in
        bash)
            source="$CONFIG_MODULE_PAYLOAD/$__APT_FAST_BASH_PAYLOAD"
            target="$__APT_FAST_BASH_TARGET"
            ;;
        zsh)
            source="$CONFIG_MODULE_PAYLOAD/$__APT_FAST_ZSH_PAYLOAD"
            target="$__APT_FAST_ZSH_TARGET"
            ;;
        *)
            log_error "Unsupported apt-fast completion selection: $shell"

            return 1
            ;;
    esac

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

install_vendor_completion() {
    local shell="$1"
    local source
    local target
    local temporary_file

    case "$shell" in
        bash)
            source="$__APT_FAST_BASH_VENDOR_URL"
            target="$__APT_FAST_BASH_TARGET"
            ;;
        zsh)
            source="$__APT_FAST_ZSH_VENDOR_URL"
            target="$__APT_FAST_ZSH_TARGET"
            ;;
        *)
            log_error "Unsupported apt-fast completion selection: $shell"

            return 1
            ;;
    esac

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

uninstall_completion() {
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
