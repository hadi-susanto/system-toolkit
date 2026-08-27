#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/resolver.sh"

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses the configuration toolkit command or a shorthand module invocation.
#
# Parameters:
#   options_name    Name of the associative array that receives command state.
#   args_name       Name of the indexed array that receives command arguments.
#   arguments       Command-line arguments to parse.
#
# Returns:
#   1 when the first parameter is an option instead of a command or module.
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
    local canonical_id
    local resolve_status=0

    __parse_args options args "$@" || return $?
    route_command_help options args

    case "${options[CMD]}" in
        help)
            exec bash "$CONFIG_COMMAND/help.sh" "${args[@]}"
            ;;
        configure)
            exec bash "$CONFIG_COMMAND/configure.sh" "${args[@]}"
            ;;
        list)
            exec bash "$CONFIG_COMMAND/list.sh" "${args[@]}"
            ;;
        status)
            exec bash "$CONFIG_COMMAND/status.sh" "${args[@]}"
            ;;
        *)
            if canonical_id="$(resolve_module "$CONFIG_MODULES" "${options[CMD]}")"; then
                exec bash "$CONFIG_COMMAND/configure.sh" "$canonical_id" "${args[@]}"
            else
                resolve_status=$?
            fi

            case "$resolve_status" in
                2)
                    log_error "Ambiguous configuration module name: ${options[CMD]}"
                    ;;
                *)
                    log_error "Unknown configuration module: ${options[CMD]}"
                    ;;
            esac

            bash "$CONFIG_COMMAND/help.sh" >&2

            return "$resolve_status"
            ;;
    esac
}

main "$@"
