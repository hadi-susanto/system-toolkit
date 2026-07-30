#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/resolver.sh"
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
        log_error "Unknown install option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( ${#args_ref[@]} != 1 )); then
        log_error "The install command requires exactly one configuration module"

        return 1
    fi
}

__validate_install_scripts() {
    local canonical_id="$1"
    local module_dir="$2"
    local check_script="$module_dir/check_install_requirements.sh"
    local install_script="$module_dir/install.sh"

    if [[ ! -f "$check_script" ]] || [[ -L "$check_script" ]]; then
        log_error "Configuration module is missing check_install_requirements.sh: $canonical_id"

        return 1
    fi

    if [[ ! -f "$install_script" ]] || [[ -L "$install_script" ]]; then
        log_error "Configuration module is missing install.sh: $canonical_id"

        return 1
    fi
}

main() {
    local -A options
    local -A metadata
    local -a args
    local canonical_id
    local module_dir
    local check_script
    local install_script
    local check_status=0
    local install_status=0
    local resolve_status=0

    __parse_args options args "$@"
    if ! __validate_options options args; then
        bash "$CONFIG_COMMAND/help.sh" install >&2

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

        return "$resolve_status"
    fi

    parse_config_metadata "$canonical_id" metadata || return $?

    module_dir="$CONFIG_MODULES/$canonical_id"
    __validate_install_scripts "$canonical_id" "$module_dir" || return $?

    check_script="$module_dir/check_install_requirements.sh"
    install_script="$module_dir/install.sh"

    export CONFIG_MODULE_ID="$canonical_id"
    export CONFIG_MODULE_DIR="$module_dir"
    export CONFIG_MODULE_PAYLOAD="$CONFIG_PAYLOAD/$canonical_id"
    export CONFIG_FORCE="false"

    if (( options[FORCE] )); then
        CONFIG_FORCE="true"
    fi

    log_info "Checking configuration module installation: ${metadata[NAME]} [$canonical_id]"
    bash "$check_script" || check_status=$?

    case "$check_status" in
        "$CONFIG_CHECK_PROCEED")
            ;;
        "$CONFIG_CHECK_SKIP")
            if (( ! options[FORCE] )); then
                log_info "Configuration module installation is already satisfied; skipping: $canonical_id"

                return 0
            fi

            log_warn "Forcing configuration module installation after a skip result: $canonical_id"
            ;;
        "$CONFIG_CHECK_BLOCK")
            log_error "Configuration module installation is blocked: $canonical_id"

            return "$check_status"
            ;;
        *)
            log_error "Configuration module install check failed with status $check_status: $canonical_id"

            return "$check_status"
            ;;
    esac

    log_info "Installing configuration module: ${metadata[NAME]} [$canonical_id]"
    bash "$install_script" || install_status=$?

    if (( install_status != 0 )); then
        log_error "Configuration module installation failed with status $install_status: $canonical_id"

        return "$install_status"
    fi

    log_info "Installed configuration module: $canonical_id"
}

main "$@"
