if [[ -n "${__SYSKIT_COMMON_LOADED:-}" ]]; then
    return 0
fi

readonly __SYSKIT_COMMON_LOADED=1

if [[ -n "${NO_COLOR:-}" ]]; then
    readonly COLOR_GREEN=''
    readonly COLOR_RED=''
    readonly COLOR_YELLOW=''
    readonly COLOR_CYAN=''
    readonly COLOR_RESET=''
elif [[ -n "${FORCE_COLOR:-}" ]] || [[ -t 1 ]]; then
    readonly COLOR_GREEN=$'\033[0;32m'
    readonly COLOR_RED=$'\033[0;31m'
    readonly COLOR_YELLOW=$'\033[0;33m'
    readonly COLOR_CYAN=$'\033[0;36m'
    readonly COLOR_RESET=$'\033[0m'
else
    readonly COLOR_GREEN=''
    readonly COLOR_RED=''
    readonly COLOR_YELLOW=''
    readonly COLOR_CYAN=''
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
# validate_no_options <command> [arguments...]
#
# Rejects command options while allowing positional arguments.
#
# Parameters:
#   command      Command name used in error messages.
#   arguments    Command arguments to validate.
#
# Returns:
#   1 when an option is found before an explicit "--" separator.
#
validate_no_options() {
    local command="$1"
    shift

    local argument

    for argument in "$@"; do
        case "$argument" in
            --)
                return 0
                ;;
            -*)
                log_error "Unknown option for '$command': $argument"

                return 1
                ;;
        esac
    done
}
