if (( ${__SYSKIT_JETBRAINS_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_JETBRAINS_CONFIG_LIB_LOADED=1

readonly __JETBRAINS_SYSCTL_FILE="/etc/sysctl.d/idea.conf"
readonly __JETBRAINS_SYSCTL_KEY="fs.inotify.max_user_watches"
readonly __JETBRAINS_PROC_FILE="/proc/sys/fs/inotify/max_user_watches"
readonly __JETBRAINS_DEFAULT_WATCHES=1048576
readonly __JETBRAINS_MAX_WATCHES=2147483647

##
# jetbrains_valid_watches <value>
#
# Checks that a value is a positive integer within the kernel limit.
#
# Parameters:
#   value    Candidate watches limit.
#
# Returns:
#   1 when the value is not a positive integer or exceeds the maximum.
#
jetbrains_valid_watches() {
    local value="$1"

    if [[ ! "$value" =~ ^[1-9][0-9]{0,9}$ ]]; then
        return 1
    fi

    (( value <= __JETBRAINS_MAX_WATCHES ))
}

##
# jetbrains_running_watches
#
# Reads the inotify watches limit currently enforced by the kernel.
#
# Output:
#   Prints the running limit.
#
# Returns:
#   1 when the value cannot be read.
#
jetbrains_running_watches() {
    local value

    if ! read -r value <"$__JETBRAINS_PROC_FILE"; then
        return 1
    fi

    printf '%s\n' "$value"
}

##
# jetbrains_inotify_state
#
# Reads the watches limit persisted in the SysKit sysctl drop-in file.
#
# Output:
#   Prints the configured limit when the state is 0.
#
# Returns:
#   1 when the file does not exist.
#   2 when the file is symbolic, not a regular file, unreadable, or does not
#   contain exactly one valid limit.
#
jetbrains_inotify_state() {
    local line
    local value=""
    local count=0
    local -a lines=()
    local pattern="^[[:space:]]*fs\\.inotify\\.max_user_watches[[:space:]]*=[[:space:]]*([0-9]+)[[:space:]]*$"

    if [[ ! -e "$__JETBRAINS_SYSCTL_FILE" ]] && [[ ! -L "$__JETBRAINS_SYSCTL_FILE" ]]; then
        return 1
    fi

    if [[ -L "$__JETBRAINS_SYSCTL_FILE" ]] ||
        [[ ! -f "$__JETBRAINS_SYSCTL_FILE" ]] ||
        [[ ! -r "$__JETBRAINS_SYSCTL_FILE" ]]; then
        return 2
    fi

    if ! mapfile -t lines <"$__JETBRAINS_SYSCTL_FILE"; then
        return 2
    fi

    for line in "${lines[@]}"; do
        if [[ "$line" =~ $pattern ]]; then
            value="${BASH_REMATCH[1]}"
            ((count += 1))
        fi
    done

    if (( count != 1 )) || ! jetbrains_valid_watches "$value"; then
        return 2
    fi

    printf '%s\n' "$value"
}

##
# __jetbrains_reload_sysctl
#
# Reloads every sysctl configuration file so the change takes effect now.
#
# Returns:
#   1 when sysctl fails.
#
__jetbrains_reload_sysctl() {
    if ! sudo sysctl --system >/dev/null; then
        log_error "Failed to reload sysctl configuration"

        return 1
    fi
}

##
# write_jetbrains_inotify_limit <limit>
#
# Writes the sysctl drop-in file and reloads sysctl.
#
# Parameters:
#   limit    Positive integer watches limit.
#
# Returns:
#   1 when the limit or target is invalid, or writing or reloading fails.
#
write_jetbrains_inotify_limit() {
    local limit="$1"
    local tmp_file

    if ! jetbrains_valid_watches "$limit"; then
        log_error "Invalid inotify watches limit: $limit"

        return 1
    fi

    if [[ -L "$__JETBRAINS_SYSCTL_FILE" ]] ||
        { [[ -e "$__JETBRAINS_SYSCTL_FILE" ]] && [[ ! -f "$__JETBRAINS_SYSCTL_FILE" ]]; }; then
        log_error "Invalid sysctl file: $__JETBRAINS_SYSCTL_FILE"

        return 1
    fi

    if ! tmp_file="$(mktemp)"; then
        log_error "Failed to create temporary sysctl file"

        return 1
    fi

    if ! printf '# Managed by SysKit (ide/jetbrains)\n%s = %s\n' \
        "$__JETBRAINS_SYSCTL_KEY" "$limit" >"$tmp_file"; then
        log_error "Failed to write temporary sysctl file"
        rm -f -- "$tmp_file"

        return 1
    fi

    if ! sudo install -m 0644 -o root -g root -- "$tmp_file" "$__JETBRAINS_SYSCTL_FILE"; then
        log_error "Failed to install sysctl file: $__JETBRAINS_SYSCTL_FILE"
        rm -f -- "$tmp_file"

        return 1
    fi

    rm -f -- "$tmp_file"

    __jetbrains_reload_sysctl || return $?
    log_info "Set $__JETBRAINS_SYSCTL_KEY to $limit; restart the IDE to apply it"
}

##
# remove_jetbrains_inotify_limit
#
# Removes the sysctl drop-in file and reloads sysctl. The running kernel value
# is kept until another sysctl file sets it or the system reboots.
#
# Returns:
#   1 when the target is invalid, or removal or reloading fails.
#
remove_jetbrains_inotify_limit() {
    if [[ ! -e "$__JETBRAINS_SYSCTL_FILE" ]] && [[ ! -L "$__JETBRAINS_SYSCTL_FILE" ]]; then
        log_warn "Inotify watches limit is not configured"

        return 0
    fi

    if ! sudo rm -f -- "$__JETBRAINS_SYSCTL_FILE"; then
        log_error "Failed to remove sysctl file: $__JETBRAINS_SYSCTL_FILE"

        return 1
    fi

    __jetbrains_reload_sysctl || return $?
    log_info "Removed $__JETBRAINS_SYSCTL_FILE; the running limit resets on reboot unless another sysctl file sets it"
}
