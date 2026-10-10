if (( ${__SYSKIT_EDGE_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_EDGE_LIB_LOADED=1

readonly __EDGE_CHANNELS=(
    "stable"
    "beta"
    "dev"
    "canary"
)

##
# edge_cron_path <channel>
#
# Resolves the Microsoft Edge cron script path for a release channel.
#
# Parameters:
#   channel    One of stable, beta, dev, or canary.
#
# Output:
#   Prints the cron script path.
#
# Returns:
#   1 when the channel is unsupported.
#
edge_cron_path() {
    local channel="$1"

    case "$channel" in
        stable)
            printf '%s\n' "/opt/microsoft/msedge/cron/microsoft-edge"
            ;;
        beta | dev | canary)
            printf '/opt/microsoft/msedge-%s/cron/microsoft-edge-%s\n' \
                "$channel" "$channel"
            ;;
        *)
            return 1
            ;;
    esac
}

##
# edge_cron_state <path>
#
# Resolves whether a cron script is enabled. The script is enabled when it is
# executable, because run-parts skips non-executable files.
#
# Parameters:
#   path    Cron script path.
#
# Returns:
#   0 when the cron job is enabled.
#   1 when the cron job is disabled.
#   2 when the cron script does not exist.
#   3 when the path is a symbolic link or not a regular file.
#
edge_cron_state() {
    local path="$1"

    if [[ ! -e "$path" ]] && [[ ! -L "$path" ]]; then
        return 2
    fi

    if [[ -L "$path" ]] || [[ ! -f "$path" ]]; then
        return 3
    fi

    if [[ -x "$path" ]]; then
        return 0
    fi

    return 1
}
