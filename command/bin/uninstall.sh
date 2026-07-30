#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/checksum.sh"
source "$BIN_LIB/executables.sh"
source "$BIN_LIB/scope.sh"

##
# __parse_args <options_name> <args_name> [arguments...]
#
# Parses uninstallation scope, all, and executable-name arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives option state.
#   args_name       Name of the indexed array that receives executable names.
#   arguments       Command-line arguments to parse.
#
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"
    local local_dir
    local global_dir

    local_dir="$(local_install_dir)" || return $?
    global_dir="$(global_install_dir)"

    options_ref=(
        [ALL]=0
        [CMD]="uninstall"
        [GLOBAL]=0
        [INSTALL_DIR]="$local_dir"
        [INVALID_OPTION]=""
        [LOCAL]=0
        [SCOPE]="local"
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -l | --local)
                options_ref[LOCAL]=1
                options_ref[SCOPE]="local"
                options_ref[INSTALL_DIR]="$local_dir"
                ;;
            -g | --global)
                options_ref[GLOBAL]=1
                options_ref[SCOPE]="global"
                options_ref[INSTALL_DIR]="$global_dir"
                ;;
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
    local options_name="${1}"
    local args_name="${2}"
    local -n options_ref="${options_name}"
    local -n args_ref="${args_name}"

    if [[ -n "${options_ref[INVALID_OPTION]}" ]]; then
        log_error "Unknown uninstall option: ${options_ref[INVALID_OPTION]}"

        return 1
    fi

    if (( options_ref[LOCAL] && options_ref[GLOBAL] )); then
        log_error "Cannot combine local and global scope options"

        return 1
    fi

    if (( options_ref[ALL] && ${#args_ref[@]} > 0 )); then
        log_error "Cannot combine --all with executable names"

        return 1
    fi

    if (( ! options_ref[ALL] && ${#args_ref[@]} == 0 )); then
        log_error "At least one executable name or --all is required"

        return 1
    fi

    if [[ "${options_ref[SCOPE]}" == "global" ]] && (( EUID != 0 )); then
        log_error "Global uninstallation requires elevated privileges"
        log_error "Run: sudo syskit-bin.sh uninstall --global <name>"

        return 1
    fi

    if [[ -e "${options_ref[INSTALL_DIR]}" ]] &&
        [[ ! -d "${options_ref[INSTALL_DIR]}" ]]; then
        log_error "Installation path is not a directory: ${options_ref[INSTALL_DIR]}"

        return 1
    fi

    if ! install_dir_in_path "${options_ref[INSTALL_DIR]}"; then
        log_warn "${options_ref[INSTALL_DIR]} is not present in PATH"
    fi
}

__resolve_args_to_executables() {
    local args_name="$1"
    local executables_name="$2"
    local -n args_ref="$args_name"
    local -n executables_ref="$executables_name"
    local -A seen=()
    local name

    executables_ref=()

    for name in "${args_ref[@]}"; do
        resolve_bin_executable "$name" >/dev/null || return $?

        if (( seen["$name"] )); then
            continue
        fi

        seen["$name"]=1
        executables_ref+=("$name")
    done
}

__uninstall_executable() {
    local name="$1"
    local options_name="$2"
    local -n options_ref="$options_name"
    local source="${BIN_PAYLOAD}/${name}"
    local target="${options_ref[INSTALL_DIR]}/$name"
    local checksum_status=0

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        log_warn "Executable is not installed; skipping: $target"

        return 0
    fi

    if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
        log_error "Uninstall target is a directory: $target"

        return 1
    fi

    if checksums_match "$source" "$target"; then
        checksum_status=0
    else
        checksum_status=$?
    fi

    case "$checksum_status" in
        0)
            ;;
        1)
            log_warn "Installed checksum differs; assuming an update is available: $name"
            ;;
        2)
            log_error "Failed to checksum executable source: $source"

            return 1
            ;;
        3)
            log_error "Failed to checksum installed executable: $target"

            return 1
            ;;
        127)
            log_error "Required command is unavailable: sha256sum"

            return 1
            ;;
    esac

    if ! rm -f -- "$target"; then
        log_error "Failed to remove executable: $target"

        return 1
    fi

    log_info "Uninstalled executable: $name"
}

main() {
    local -A options
    local -a args
    local -a executables
    local name
    local failed=0

    __parse_args options args "$@"
    __validate_options options args || return $?

    if (( options[ALL] )); then
        list_bin_executables executables

        if (( ${#executables[@]} == 0 )); then
            log_error "No SysKit executables are available to uninstall"

            return 1
        fi
    else
        __resolve_args_to_executables args executables || return $?
    fi

    for name in "${executables[@]}"; do
        if __uninstall_executable "$name" options; then
            continue
        fi

        log_error "Failed to uninstall executable: $name"
        failed=1
    done

    return "$failed"
}

main "$@"
