#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/resolver.sh"
source "$SHELL_LIB/interface_loader.sh"
source "$SHELL_LIB/modules.sh"

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses all, force, and module arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives option state.
#   args_name       Name of the indexed array that receives module names or
#                   canonical IDs.
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
    if [[ -n "${options_ref[INVALID_OPTION]}" ]]; then
        log_error "Unknown uninstall option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( options_ref[ALL] && ${#args_ref[@]} > 0 )); then
        log_error "Cannot combine --all with module IDs"

        return 1
    fi

    if (( ! options_ref[ALL] && ${#args_ref[@]} == 0 )); then
        log_error "At least one module or --all is required"
        log_warn "Use --all with caution; it will uninstall all installed modules"

        return 1
    fi
}

__resolve_modules() {
    local args_name="$1"
    local modules_name="$2"
    local -n args_ref="$args_name"
    local -n modules_ref="$modules_name"
    local -A seen=()
    local requested_module
    local canonical_id
    local resolve_status=0

    modules_ref=()

    for requested_module in "${args_ref[@]}"; do
        if canonical_id="$(resolve_module "$SHELL_PAYLOAD" "$requested_module")"; then
            :
        else
            resolve_status=$?

            case "$resolve_status" in
                2)
                    log_error "Ambiguous shell module name: $requested_module"
                    ;;
                *)
                    log_error "Unknown shell module: $requested_module"
                    ;;
            esac

            return "$resolve_status"
        fi

        if (( seen["$canonical_id"] )); then
            continue
        fi

        seen["$canonical_id"]=1
        modules_ref+=("$canonical_id")
    done
}

__uninstall_module() {
    local shell="$1"
    local module="$2"
    local force="$3"

    if ! support_module "$module"; then
        log_warn "Module '$module' is not supported by this shell: $shell"

        return 1
    fi

    if ! module_installed "$module"; then
        if (( ! force )); then
            log_warn "Shell module is not installed; skipping: $module"

            return 0
        fi

        log_warn "Force uninstallation shell module: $module"
    fi

    if ! uninstall_module "$module"; then
        log_error "Failed to uninstall shell module: $module"

        return 1
    fi

    log_info "Uninstalled shell module: $module"
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
        "$shell" "support_module" "module_installed" "uninstall_module" || return 1
    __parse_args options args "$@"
    __validate_options options args || return $?

    if (( options[FORCE] )); then
        log_warn "Force uninstallation is enabled"
    fi

    if (( options[ALL] )); then
        list_shell_modules modules

        if (( ${#modules[@]} == 0 )); then
            log_error "No SysKit shell modules are available for uninstallation"

            return 1
        fi
    else
        __resolve_modules args modules || return $?
    fi

    for module in "${modules[@]}"; do
        if __uninstall_module "$shell" "$module" "${options[FORCE]}"; then
            continue
        fi

        failed=1
    done

    return "$failed"
}

main "$@"
