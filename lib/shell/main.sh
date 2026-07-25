#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/__interface_loader.sh"

##
# __parse_args <options_name> <args_name> <shell> [arguments...]
#
# Parses the shell toolkit command and preserves its arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives command state.
#   args_name       Name of the indexed array that receives command arguments.
#   arguments       Command-line arguments to parse.
#
# Returns:
#   1 when the shell is unsupported or the first parameter is an option.
#
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [CMD]="help"
    )
    args_ref=()

    if [[ $# -eq 0 ]]; then
        return 0
    fi

    case "$1" in
        help | -h | --help)
            options_ref[CMD]="help"
            ;;
        -*)
            log_error "The first parameter should be a command; options must follow a command: $1"

            return 1
            ;;
        *)
            options_ref[CMD]="$1"
            ;;
    esac

    shift
    args_ref=("$@")
}

main() {
    local shell="${1:-}"

    if (( $# > 0 )); then
        shift
    fi

    if ! exists_shell_interface "$shell"; then
        log_error "Unsupported shell: ${shell:-<missing>}"

        return 1
    fi

    local -A options
    local -a args

    __parse_args options args "$@" || return $?

    case "${options[CMD]}" in
        help)
            exec bash "$SHELL_LIB/help.sh" "$shell" "${args[@]}"
            ;;
        install)
            exec bash "$SHELL_LIB/install.sh" "$shell" "${args[@]}"
            ;;
        uninstall)
            exec bash "$SHELL_LIB/uninstall.sh" "$shell" "${args[@]}"
            ;;
        activate)
            exec bash "$SHELL_LIB/activate.sh" "$shell" "${args[@]}"
            ;;
        deactivate)
            exec bash "$SHELL_LIB/deactivate.sh" "$shell" "${args[@]}"
            ;;
        status)
            exec bash "$SHELL_LIB/status.sh" "$shell" "${args[@]}"
            ;;
        *)
            log_error "Unsupported $shell toolkit command: ${options[CMD]}"
            bash "$SHELL_LIB/help.sh" "$shell" >&2

            return 1
            ;;
    esac
}

main "$@"
