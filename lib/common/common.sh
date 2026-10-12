if [[ -n "${__SYSKIT_COMMON_LOADED:-}" ]]; then
    return 0
fi

readonly __SYSKIT_COMMON_LOADED=1

if [[ -z "${NO_COLOR:-}" ]] &&
    { [[ -n "${FORCE_COLOR:-}" ]] || [[ -t 1 ]]; }; then
    readonly COLOR_GREEN=$'\033[0;32m'
    readonly COLOR_RED=$'\033[0;31m'
    readonly COLOR_YELLOW=$'\033[0;33m'
    readonly COLOR_CYAN=$'\033[0;36m'
    readonly COLOR_GRAY=$'\033[90m'
    readonly COLOR_RESET=$'\033[0m'
else
    readonly COLOR_GREEN=''
    readonly COLOR_RED=''
    readonly COLOR_YELLOW=''
    readonly COLOR_CYAN=''
    readonly COLOR_GRAY=''
    readonly COLOR_RESET=''
fi

##
# log_info <message...>
#
# Writes an informational message to stderr.
#
# Parameters:
#   message    Message text to write.
#
log_info() {
    printf '%b[INFO]%b %s\n' "$COLOR_CYAN" "$COLOR_RESET" "$*" >&2
}

##
# log_warn <message...>
#
# Writes a yellow warning message to stderr when colors are enabled.
#
# Parameters:
#   message    Message text to write.
#
log_warn() {
    printf '%b[WARN]%b %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*" >&2
}

##
# log_error <message...>
#
# Writes a red error message to stderr when colors are enabled.
#
# Parameters:
#   message    Message text to write.
#
log_error() {
    printf '%b[ERROR]%b %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
}

##
# sudo <command...>
#
# Shadows the sudo binary for every SysKit script that sources this library.
# Logs the exact command and warns that a password may be requested, then runs
# the real sudo. Direct calls such as /usr/bin/sudo or `command sudo` bypass it.
# Precede each call with a log_info that states the human reason.
#
# Parameters:
#   command    Arguments passed through to sudo unchanged.
#
# Returns:
#   The exit status of the real sudo.
#
sudo() {
    log_info "Running: sudo $(printf '%q ' "$@")(sudo may ask for your password)"

    command sudo "$@"
}

##
# route_command_help <options_name> <args_name>
#
# Rewrites "<command> help", "<command> -h", and "<command> --help" to the
# equivalent "help <command>" dispatch state.
#
# Parameters:
#   options_name    Name of the associative array containing the CMD key.
#   args_name       Name of the indexed array containing command arguments.
#
route_command_help() {
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"
    local command="${options_ref[CMD]}"

    if (( ${#args_ref[@]} == 0 )); then
        return 0
    fi

    case "${args_ref[0]}" in
        help | -h | --help)
            options_ref[CMD]="help"
            args_ref=("$command")
            ;;
    esac

    return 0
}
