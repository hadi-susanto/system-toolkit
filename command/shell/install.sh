#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/interface_loader.sh"
source "$SHELL_LIB/modules.sh"

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses all, force, and canonical module ID arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives option state.
#   args_name       Name of the indexed array that receives canonical module
#                   IDs.
#   arguments       Command-line arguments to parse.
#
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [ALL]=0
        [FORCE]=0
        [INVALID_OPTION]=""
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -a | --all | all)
                options_ref[ALL]=1
                ;;
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

__validate_options() {
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"
    local module

    if [[ -n "${options_ref[INVALID_OPTION]}" ]]; then
        log_error "Unknown install option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( options_ref[ALL] && ${#args_ref[@]} > 0 )); then
        log_error "Cannot combine --all with module IDs"

        return 1
    fi

    if (( ! options_ref[ALL] && ${#args_ref[@]} == 0 )); then
        log_error "At least one canonical module ID or --all is required"

        return 1
    fi

    for module in "${args_ref[@]}"; do
        if ! resolve_shell_module "$module" >/dev/null; then
            return 1
        fi
    done
}

__deduplicate_modules() {
    local args_name="$1"
    local modules_name="$2"
    local -n args_ref="$args_name"
    local -n modules_ref="$modules_name"
    local -A seen=()
    local module

    modules_ref=()

    for module in "${args_ref[@]}"; do
        if (( seen["$module"] )); then
            continue
        fi

        seen["$module"]=1
        modules_ref+=("$module")
    done
}

##
# __check_module_dependencies <canonical_id>
#
# Checks a module's dedicated dependency script when available. Otherwise,
# checks whether the module-name segment is available as a command.
#
# Parameters:
#   canonical_id    Module ID in <category>/<module> format.
#
# Returns:
#   The dedicated dependency check status, or 1 when the fallback command is
#   unavailable.
#
__check_module_dependencies() {
    local canonical_id="$1"
    local check_script="$SHELL_MODULES/$canonical_id/check_dependencies.sh"
    local command_name="${canonical_id##*/}"

    if [[ -f "$check_script" ]] && [[ ! -L "$check_script" ]]; then
        if bash "$check_script"; then
            return 0
        fi

        return 1
    fi

    command -v "$command_name" >/dev/null 2>&1
}

__install_module() {
    local shell="$1"
    local module="$2"
    local force="$3"

    if ! support_module "$module"; then
        log_warn "Module '$module' is not supported by this shell: $shell"

        return 1
    fi

    if module_installed "$module"; then
        if (( ! force )); then
            log_warn "Shell module is already installed; skipping: $module"

            return 0
        fi

        log_warn "Reinstalling shell module: $module"
    fi

    if ! __check_module_dependencies "$module"; then
        if (( ! force )); then
            log_error "Shell module dependency check failed for module: $module"
            log_info "Please inpect the logs above"

            return 1
        fi

        log_warn "Forcing shell module installation despite failed dependency checks: $module"
    fi

    if ! install_module "$module"; then
        log_error "Failed to install shell module: $module"

        return 1
    fi

    log_info "Installed shell module: $module"
}

main() {
    local shell="${1:-}"
    local -A options
    local -a args
    local -a modules
    local module
    local failed=0

    if (( $# > 0 )); then
        shift
    fi

    load_shell_interface \
        "$shell" "support_module" "module_installed" "install_module" || return 1
    __parse_args options args "$@"
    __validate_options options args || return $?

    if (( options[FORCE] )); then
        log_warn "Force installation is enabled"
    fi

    if (( options[ALL] )); then
        list_shell_modules modules

        if (( ${#modules[@]} == 0 )); then
            log_error "No SysKit shell modules are available to install"

            return 1
        fi
    else
        __deduplicate_modules args modules
    fi

    for module in "${modules[@]}"; do
        if __install_module "$shell" "$module" "${options[FORCE]}"; then
            continue
        fi

        failed=1
    done

    return "$failed"
}

main "$@"
