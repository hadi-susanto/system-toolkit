#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/__interface_loader.sh"
source "$SHELL_LIB/__modules.sh"

__boolean_to_icon() {
    if "$@"; then
        printf '%s[✓]%s\n' "$COLOR_GREEN" "$COLOR_RESET"
    else
        printf '%s[✗]%s\n' "$COLOR_RED" "$COLOR_RESET"
    fi
}

__resolve_install_icon() {
    local module="$1"
    local source
    local target

    if ! target="$(installed_module_path "$module")"; then
        printf '%s[✗]%s\n' "$COLOR_RED" "$COLOR_RESET"

        return 0
    fi

    if ! source="$(module_source_path "$module")"; then
        # Inconsistency detected...
        log_error "$module was installed, but we can't determine it's source file"
        printf '%s[?]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

        return 0
    fi

    # Installed, need to check the checksum, different checksum mean update available
    local source_checksum
    local target_checksum

    if ! source_checksum="$(sha256sum -- "$source" 2>/dev/null)"; then
        printf '%s[?]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

        return 0
    fi

    if ! target_checksum="$(sha256sum -- "$target" 2>/dev/null)"; then
        printf '%s[?]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

        return 0
    fi

    source_checksum="${source_checksum%% *}"
    target_checksum="${target_checksum%% *}"

    if [[ "${source##*/}" == "${target##*/}" ]] &&
        [[ "$source_checksum" == "$target_checksum" ]]; then
        printf '%s[✓]%s\n' "$COLOR_GREEN" "$COLOR_RESET"
    else
        printf '%s[↑]%s' "$COLOR_YELLOW" "$COLOR_RESET"
    fi
}

__default_shell() {
    local shell="${1:-}"

    local default_shell="$(current_user_shell)"
    default_shell="${default_shell##*/}"

    [[ "$shell" == "$default_shell" ]]
}

main() {
    local shell="${1:-}"
    local -a modules
    local name
    local index=1

    if (( $# > 0 )); then
        shift
    fi

    load_shell_interface \
        "$shell" "support_module" "installed_module_path" "module_source_path" "loader_active" || return 1

    if [[ $# -gt 0 ]]; then
        log_error "The status command does not accept arguments"

        return 1
    fi

    if ! command -v sha256sum >/dev/null 2>&1; then
        log_error "Required command is unavailable: sha256sum"

        return 1
    fi

    list_shell_modules modules

    printf '%3s | %-20s | %-3s | %-3s\n' \
        'No' 'Module' '[S]' '[I]'
    printf '%s\n' \
        '----+----------------------+-----+-----'

    for name in "${modules[@]}"; do
        printf '%3d | %-20s | %-6s | %-6s\n' \
            "$index" \
            "$name" \
            "$(__boolean_to_icon support_module "$name")" \
            "$(__resolve_install_icon "$name")"

        ((index += 1))
    done

    printf '\n%s status:\n  installed? %s, default? %s (current: %s), activated? %s\n' \
        "$shell" \
        "$(__boolean_to_icon shell_installed "$shell")" \
        "$(__boolean_to_icon __default_shell "$shell")" \
        "$(current_user_shell)" \
        "$(__boolean_to_icon loader_active)"

    printf 'Legend:\n'
    printf '  [S]: Indicates whether the current module supports the current shell.\n'
    printf '  [I]: Indicates whether the current module is installed for the current shell.\n'
    printf '  %s[✓]%s: Installed and up to date.\n' "$COLOR_GREEN" "$COLOR_RESET"
    printf '  %s[✗]%s: Not installed.\n' "$COLOR_RED" "$COLOR_RESET"
    printf '  %s[↑]%s: Installed; update available (checksum mismatch).\n' "$COLOR_YELLOW" "$COLOR_RESET"
    printf '  %s[?]%s: Installed; unable to verify version.\n' "$COLOR_YELLOW" "$COLOR_RESET"
}

main "$@"
