#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/__interface_loader.sh"

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses force and positional arguments for loader activation.
#
# Parameters:
#   options_name    Name of the associative array that receives option state.
#   args_name       Name of the indexed array that receives positional values.
#   arguments       Command-line arguments to parse.
#
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [FORCE]=0
        [INVALID_OPTION]=""
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                if [[ -z "${options_ref[INVALID_OPTION]}" ]]; then
                    options_ref[INVALID_OPTION]="$1"
                else
                    options_ref[INVALID_OPTION]+=", ${1}"
                fi
                ;;
            *)
                args_ref+=("$1")
                ;;
        esac

        shift
    done
}

##
# __validate_options <options_name> <args_name>
#
# Validates loader activation options and rejects positional arguments.
#
# Parameters:
#   options_name    Name of the associative array containing option state.
#   args_name       Name of the indexed array containing positional values.
#
# Returns:
#   1 when an option is unknown or a positional argument is present.
#
__validate_options() {
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    if [[ -n "${options_ref[INVALID_OPTION]}" ]]; then
        log_error "Unknown activate option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( ${#args_ref[@]} > 0 )); then
        log_error "The activate command does not accept positional arguments"

        return 1
    fi
}

__activate_loader() {
    local shell="$1"
    local force="$2"

    if ! shell_installed "$shell"; then
        if (( !force )); then
            log_error "$(shell_display_name) is not installed on your system. Unable to proceed."

            return 1
        fi

        log_warn "Forcing activation of the $(shell_display_name) shell loader even though it is not installed."
    fi

    if loader_active; then
        if (( ! force )); then
            log_warn "Shell loader is already active; skipping: $shell"

            return 0
        fi

        log_warn "Reactivating shell loader: $shell"
    fi

    if ! activate_loader; then
        log_error "Failed to activate shell loader: $shell"

        return 1
    fi

    log_info "Activated shell loader: $shell"
}

main() {
    local shell="${1:-}"
    local -A options
    local -a args

    if (( $# > 0 )); then
        shift
    fi

    load_shell_interface \
        "$shell" "shell_display_name" "loader_active" "activate_loader" || return 1
    __parse_args options args "$@"
    __validate_options options args || return $?

    if (( options[FORCE] )); then
        log_warn "Force activation is enabled"
    fi

    __activate_loader "$shell" "${options[FORCE]}"
}

main "$@"
