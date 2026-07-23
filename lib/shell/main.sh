#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

##
# __parse_args <options_name> <args_name> <shell> [arguments...]
#
# Parses the shell toolkit command and preserves its arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives command state.
#   args_name       Name of the indexed array that receives command arguments.
#   shell           Shell implementation selected by the entrypoint.
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
        [SHELL]=""
    )
    args_ref=()

    if [[ $# -eq 0 ]]; then
        log_error "A shell implementation is required"

        return 1
    fi

    case "$1" in
        bash | zsh)
            options_ref[SHELL]="$1"
            ;;
        *)
            log_error "Unsupported shell: $1"

            return 1
            ;;
    esac

    shift

    if [[ $# -eq 0 ]]; then
        return 0
    fi

    case "$1" in
        help | -h | --help)
            options_ref[CMD]="help"
            ;;
        -*)
            log_error "The first parameter should be a command; options must follow a command: $1"
            bash "$SHELL_LIB/help.sh" "${options_ref[SHELL]}" >&2

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
    local -A options
    local -a args

    __parse_args options args "$@" || return $?

    case "${options[CMD]}" in
        help)
            exec bash "$SHELL_LIB/help.sh" "${options[SHELL]}" "${args[@]}"
            ;;
        install)
            exec bash "$SHELL_LIB/install.sh" "${options[SHELL]}" "${args[@]}"
            ;;
        uninstall)
            exec bash "$SHELL_LIB/uninstall.sh" "${options[SHELL]}" "${args[@]}"
            ;;
        enable)
            exec bash "$SHELL_LIB/enable.sh" "${options[SHELL]}" "${args[@]}"
            ;;
        disable)
            exec bash "$SHELL_LIB/disable.sh" "${options[SHELL]}" "${args[@]}"
            ;;
        status)
            exec bash "$SHELL_LIB/status.sh" "${options[SHELL]}" "${args[@]}"
            ;;
        *)
            log_error "Unsupported ${options[SHELL]} toolkit command: ${options[CMD]}"
            bash "$SHELL_LIB/help.sh" "${options[SHELL]}" >&2

            return 1
            ;;
    esac
}

main "$@"
