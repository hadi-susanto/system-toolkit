#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses the configuration toolkit command and preserves its arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives command state.
#   args_name       Name of the indexed array that receives command arguments.
#   arguments       Command-line arguments to parse.
#
# Returns:
#   1 when the first parameter is an option instead of a command.
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
            bash "$CONFIG_COMMAND/help.sh" >&2

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
    route_command_help options args

    case "${options[CMD]}" in
        help)
            exec bash "$CONFIG_COMMAND/help.sh" "${args[@]}"
            ;;
        install)
            exec bash "$CONFIG_COMMAND/install.sh" "${args[@]}"
            ;;
        list)
            exec bash "$CONFIG_COMMAND/list.sh" "${args[@]}"
            ;;
        uninstall)
            exec bash "$CONFIG_COMMAND/uninstall.sh" "${args[@]}"
            ;;
        status)
            exec bash "$CONFIG_COMMAND/status.sh" "${args[@]}"
            ;;
        *)
            log_error "Unsupported configuration toolkit command: ${options[CMD]}"
            bash "$CONFIG_COMMAND/help.sh" >&2

            return 1
            ;;
    esac
}

main "$@"
