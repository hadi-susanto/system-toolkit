#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/resolver.sh"

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
        log_error "Unknown configure option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( ${#args_ref[@]} != 1 )); then
        log_error "The configure command requires exactly one configuration module"

        return 1
    fi
}

main() {
    local -A options
    local -a args
    local canonical_id
    local module_dir
    local main_script
    local configure_status=0
    local resolve_status=0

    __parse_args options args "$@"
    if ! __validate_options options args; then
        bash "$CONFIG_COMMAND/help.sh" configure >&2

        return 1
    fi

    if canonical_id="$(resolve_module "$CONFIG_MODULES" "${args[0]}")"; then
        :
    else
        resolve_status=$?

        case "$resolve_status" in
            2)
                log_error "Ambiguous configuration module name: ${args[0]}"
                ;;
            *)
                log_error "Unknown configuration module: ${args[0]}"
                ;;
        esac

        bash "$CONFIG_COMMAND/help.sh" >&2

        return "$resolve_status"
    fi

    module_dir="$CONFIG_MODULES/$canonical_id"
    main_script="$module_dir/main.sh"

    if [[ ! -f "$main_script" ]] || [[ -L "$main_script" ]]; then
        log_error "Invalid configuration module detected; missing main.sh: $canonical_id"

        return 1
    fi

    export CONFIG_MODULE_ID="$canonical_id"
    export CONFIG_MODULE_DIR="$module_dir"
    export CONFIG_MODULE_PAYLOAD="$CONFIG_PAYLOAD/$canonical_id"
    export CONFIG_FORCE="false"

    if (( options[FORCE] )); then
        CONFIG_FORCE="true"
    fi

    log_info "Configuring configuration module: $canonical_id"
    bash "$main_script" || configure_status=$?

    if (( configure_status != 0 )); then
        log_error "Configuration module failed with status $configure_status: $canonical_id"

        return "$configure_status"
    fi

    log_info "Configured configuration module: $canonical_id"
}

main "$@"
