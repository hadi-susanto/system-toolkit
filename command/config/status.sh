#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/resolver.sh"
source "$CONFIG_LIB/metadata.sh"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [ALL]=0
        [INVALID_OPTION]=""
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -a | --all | all)
                options_ref[ALL]=1
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
        log_error "Unknown status option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( options_ref[ALL] && ${#args_ref[@]} > 0 )); then
        log_error "Cannot combine --all with a configuration modules"

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
        if canonical_id="$(resolve_module "$CONFIG_MODULES" "$requested_module")"; then
            :
        else
            resolve_status=$?

            case "$resolve_status" in
                2)
                    log_error "Ambiguous config module name: $requested_module"
                    ;;
                *)
                    log_error "Unknown config module: $requested_module"
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

__print_module_status() {
    local canonical_id="$1"
    local -A metadata
    local module_dir
    local status_script
    local status=0

    parse_config_metadata "$canonical_id" metadata || return $?

    module_dir="$CONFIG_MODULES/$canonical_id"
    status_script="$module_dir/status.sh"

    if [[ ! -f "$status_script" ]] || [[ -L "$status_script" ]]; then
        log_error "Configuration module is missing status.sh: $canonical_id"

        return 1
    fi

    export CONFIG_MODULE_ID="$canonical_id"
    export CONFIG_MODULE_DIR="$module_dir"
    export CONFIG_MODULE_PAYLOAD="$CONFIG_PAYLOAD/$canonical_id"

    printf '%s\n' '----------------------------------------------------------------------'
    printf '%s %s[id: %s]%s\n' \
        "${metadata[NAME]}" \
        "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
    printf '%s\n' "${metadata[DESCRIPTION]}"
    printf '%s\n' '----------------------------------------------------------------------'

    bash "$status_script" || status=$?

    if (( status != 0 )); then
        log_error "Configuration module status failed with status $status: $canonical_id"
    fi

    return "$status"
}

main() {
    local -A options
    local -a args
    local -a modules
    local canonical_id
    local module_status=0
    local overall_status=0
    local index=0

    __parse_args options args "$@"
    if ! __validate_options options args; then
        bash "$CONFIG_COMMAND/help.sh" status >&2

        return 1
    fi

    if (( ! options[ALL] && ${#args[@]} == 0 )); then
        bash "$CONFIG_COMMAND/help.sh" status

        return $?
    fi

    if (( options[ALL] )); then
        list_config_modules modules
    else
        __resolve_modules args modules || return $?
    fi

    if (( ${#modules[@]} == 0 )); then
        printf 'No configuration modules are available.\n'

        return 0
    fi

    for canonical_id in "${modules[@]}"; do
        if (( index > 0 )); then
            printf '\n'
        fi

        module_status=0
        __print_module_status "$canonical_id" || module_status=$?

        if (( overall_status == 0 && module_status != 0 )); then
            overall_status="$module_status"
        fi

        ((index += 1))
    done

    return "$overall_status"
}

main "$@"
