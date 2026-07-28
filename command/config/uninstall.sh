#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/checks.sh"
source "$CONFIG_LIB/metadata.sh"

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

__validate_options() {
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    if [[ -n "${options_ref[INVALID_OPTION]}" ]]; then
        log_error "Unknown uninstall option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( ${#args_ref[@]} != 1 )); then
        log_error "The uninstall command requires exactly one configuration module"

        return 1
    fi
}

__validate_uninstall_scripts() {
    local canonical_id="$1"
    local module_dir="$2"
    local has_check=0
    local has_uninstall=0

    [[ -f "$module_dir/uninstall_check.sh" ]] &&
        [[ ! -L "$module_dir/uninstall_check.sh" ]] &&
        has_check=1

    [[ -f "$module_dir/uninstall.sh" ]] &&
        [[ ! -L "$module_dir/uninstall.sh" ]] &&
        has_uninstall=1

    if (( has_check && has_uninstall )); then
        return 0
    fi

    if (( ! has_check && ! has_uninstall )); then
        log_warn "Configuration module does not support uninstall: $canonical_id"

        return 1
    fi

    log_error \
        "Configuration module: $canonical_id must provide both uninstall_check.sh and uninstall.sh"

    return 1
}

main() {
    local -A options
    local -A metadata
    local -a args
    local canonical_id
    local module_dir
    local check_script
    local uninstall_script
    local check_status=0
    local uninstall_status=0

    __parse_args options args "$@"
    if ! __validate_options options args; then
        bash "$CONFIG_COMMAND/help.sh" uninstall >&2

        return 1
    fi

    canonical_id="${args[0]}"
    parse_config_metadata "$canonical_id" metadata || return $?

    module_dir="$CONFIG_MODULES/$canonical_id"
    __validate_uninstall_scripts "$canonical_id" "$module_dir" || return $?

    check_script="$module_dir/uninstall_check.sh"
    uninstall_script="$module_dir/uninstall.sh"

    export CONFIG_MODULE_ID="$canonical_id"
    export CONFIG_MODULE_DIR="$module_dir"
    export CONFIG_MODULE_PAYLOAD="$CONFIG_PAYLOAD/$canonical_id"
    export CONFIG_FORCE="false"

    if (( options[FORCE] )); then
        CONFIG_FORCE="true"
    fi

    log_info "Checking configuration module uninstallation: ${metadata[NAME]} [$canonical_id]"
    bash "$check_script" || check_status=$?

    case "$check_status" in
        "$CONFIG_CHECK_PROCEED")
            ;;
        "$CONFIG_CHECK_SKIP")
            if (( ! options[FORCE] )); then
                log_info "Configuration module uninstallation is already satisfied; skipping: $canonical_id"

                return 0
            fi

            log_warn "Forcing configuration module uninstallation after a skip result: $canonical_id"
            ;;
        "$CONFIG_CHECK_BLOCK")
            log_error "Configuration module uninstallation is blocked: $canonical_id"

            return "$check_status"
            ;;
        *)
            log_error "Configuration module uninstall check failed with status $check_status: $canonical_id"

            return "$check_status"
            ;;
    esac

    log_info "Uninstalling configuration module: ${metadata[NAME]} [$canonical_id]"
    bash "$uninstall_script" || uninstall_status=$?

    if (( uninstall_status != 0 )); then
        log_error "Configuration module uninstallation failed with status $uninstall_status: $canonical_id"

        return "$uninstall_status"
    fi

    log_info "Uninstalled configuration module: $canonical_id"
}

main "$@"
