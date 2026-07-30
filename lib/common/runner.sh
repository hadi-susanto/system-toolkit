if (( ${__SYSKIT_RUNNER_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_RUNNER_LOADED=1

##
# run_syskit_bin <executable> [arguments...]
#
# Runs a SysKit-owned executable from SYSKIT_ROOT through Bash.
#
# Parameters:
#   executable    Executable filename in the syskit-<name> format.
#   arguments     Arguments passed unchanged to the executable.
#
# Output:
#   Preserves the executable's stdout and stderr.
#
# Returns:
#   2 when the executable name is missing or invalid.
#   127 when SYSKIT_ROOT is unset or the executable is unavailable.
#   Otherwise, preserves the executable's exit status.
#
run_syskit_bin() {
    if (( $# == 0 )); then
        log_error "A SysKit executable name is required"

        return 2
    fi

    local executable="$1"
    local root="${SYSKIT_ROOT:-}"
    local executable_path
    shift

    if [[ ! "$executable" =~ ^syskit-[a-z0-9][a-z0-9-]*$ ]]; then
        log_error "Invalid SysKit executable name: $executable"

        return 2
    fi

    if [[ -z "$root" ]]; then
        log_error "SYSKIT_ROOT is not set"

        return 127
    fi

    executable_path="$root/$executable"

    if [[ ! -f "$executable_path" ]]; then
        log_error "SysKit executable is unavailable: $executable_path"

        return 127
    fi

    bash "$executable_path" "$@"
}
