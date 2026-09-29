if (( ${__SYSKIT_PASSWORD_ASTERISKS_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_PASSWORD_ASTERISKS_LIB_LOADED=1

readonly __PASSWORD_ASTERISKS_ENABLED_FILE="/etc/sudoers.d/0pwfeedback"
readonly __PASSWORD_ASTERISKS_DISABLED_FILE="/etc/sudoers.d/0pwfeedback.disabled"

##
# password_asterisks_state
#
# Resolves whether the Linux Mint sudo password-feedback file is enabled or
# disabled.
#
# Returns:
#   0 when password feedback is enabled.
#   1 when password feedback is disabled.
#   2 when neither sudoers file exists.
#   3 when both files exist or either path is a symbolic link.
#
password_asterisks_state() {
    local enabled_exists=0
    local disabled_exists=0

    if [[ -L "$__PASSWORD_ASTERISKS_ENABLED_FILE" ]] ||
        [[ -L "$__PASSWORD_ASTERISKS_DISABLED_FILE" ]]; then
        return 3
    fi

    if [[ -e "$__PASSWORD_ASTERISKS_ENABLED_FILE" ]] &&
        [[ ! -f "$__PASSWORD_ASTERISKS_ENABLED_FILE" ]]; then
        return 3
    fi

    if [[ -e "$__PASSWORD_ASTERISKS_DISABLED_FILE" ]] &&
        [[ ! -f "$__PASSWORD_ASTERISKS_DISABLED_FILE" ]]; then
        return 3
    fi

    if [[ -f "$__PASSWORD_ASTERISKS_ENABLED_FILE" ]]; then
        enabled_exists=1
    fi

    if [[ -f "$__PASSWORD_ASTERISKS_DISABLED_FILE" ]]; then
        disabled_exists=1
    fi

    if (( enabled_exists && ! disabled_exists )); then
        return 0
    fi

    if (( ! enabled_exists && disabled_exists )); then
        return 1
    fi

    if (( ! enabled_exists && ! disabled_exists )); then
        return 2
    fi

    return 3
}
