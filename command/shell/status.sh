#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/checksum.sh"
source "$SHELL_LIB/interface_loader.sh"
source "$SHELL_LIB/modules.sh"

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
    local checksum_status=0

    if ! target="$(installed_module_path "$module")"; then
        printf '%s[✗]%s (not installed)\n' "$COLOR_RED" "$COLOR_RESET"

        return 0
    fi

    if ! source="$(module_source_path "$module")"; then
        # Inconsistency detected...
        log_error "$module was installed, but we can't determine its source file"
        printf '%s[?]%s (source-file missing)\n' "$COLOR_YELLOW" "$COLOR_RESET"

        return 0
    fi

    if checksums_match "$source" "$target"; then
        checksum_status=0
    else
        checksum_status=$?
    fi

    case "$checksum_status" in
        0)
            printf '%s[✓]%s (installed)\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[↑]%s (update available)\n' "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
        2)
            printf '%s[?]%s (source-checksum fail)\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 2
            ;;
        3)
            printf '%s[?]%s (target-checksum fail)\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 3
            ;;
        127)
            printf '%s[?]%s (sha256sum unavailable)\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 127
            ;;
    esac
}

__default_shell() {
    local shell="${1:-}"

    local default_shell="$(current_user_shell)"
    default_shell="${default_shell##*/}"

    [[ "$shell" == "$default_shell" ]]
}

__show_loader_status() {
    local shell="$1"

    if ! shell_installed "$shell"; then
        printf '%s not installed\n' "$shell"

        return 2
    fi

    if ! loader_active; then
        printf '%s loader inactive\n' "$shell"

        return 1
    fi

    printf '%s loader active\n' "$shell"
}

__show_module_status() {
    local canonical_id="$1"

    if ! resolve_shell_module "$canonical_id" >/dev/null 2>&1; then
        printf 'invalid canonical id: %s\n' "$canonical_id"

        return 2
    fi

    if ! module_installed "$canonical_id"; then
        printf '%s not installed\n' "$canonical_id"

        return 1
    fi

    printf '%s installed\n' "$canonical_id"
}

__show_full_status() {
    local shell="$1"
    local -a modules
    local name
    local install_icon
    local index=1
    local failed=0

    list_shell_modules modules

    printf '%3s | %-20s | %-3s | %-3s\n' \
        'No' 'Module' '[S]' '[I]'
    printf '%s\n' \
        '----+----------------------+-----+-----'

    for name in "${modules[@]}"; do
        if ! install_icon="$(__resolve_install_icon "$name")"; then
            failed=1
        fi

        printf '%3d | %-20s | %-6s | %-6s\n' \
            "$index" \
            "$name" \
            "$(__boolean_to_icon support_module "$name")" \
            "$install_icon"

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

    return "$failed"
}

##
# __parse_args <options_name> <args_name> [target]
#
# Parses the optional status target, defaulting to the full report.
#
# Parameters:
#   options_name    Name of the associative array that receives command state.
#   args_name       Name of the indexed array reserved for positional values.
#   target          Optional all, loader, or canonical module ID target.
#
# Returns:
#   1 when more than one target is provided.
#
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [CMD]="all"
    )
    args_ref=()

    if (( $# > 1 )); then
        log_error "The status command accepts zero or one argument"

        return 1
    fi

    if (( $# == 1 )); then
        options_ref[CMD]="$1"
    fi
}

main() {
    local shell="${1:-}"
    local -A options
    local -a args

    if (( $# > 0 )); then
        shift
    fi

    __parse_args options args "$@" || return $?

    load_shell_interface \
        "$shell" \
        "support_module" \
        "installed_module_path" \
        "module_source_path" \
        "loader_active" \
        "module_installed" || return 1

    case "${options[CMD]}" in
        '' | all)
            __show_full_status "$shell"
            ;;
        loader)
            __show_loader_status "$shell"
            ;;
        *)
            __show_module_status "${options[CMD]}"
            ;;
    esac
}

main "$@"
