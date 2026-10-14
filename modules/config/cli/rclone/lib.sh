if (( ${__SYSKIT_RCLONE_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_RCLONE_CONFIG_LIB_LOADED=1

readonly __RCLONE_UNIT_DIR="$HOME/.config/systemd/user"
readonly __RCLONE_UNIT_PREFIX="rclone-"
readonly __RCLONE_DEFAULT_CACHE_MODE="writes"
readonly __RCLONE_DEFAULT_CACHE_DIR="$HOME/.cache/rclone"
readonly __RCLONE_DEFAULT_MAX_SIZE="1G"
readonly __RCLONE_DEFAULT_MAX_AGE="720h"
readonly __RCLONE_CACHE_MODES=(
    "off"
    "minimal"
    "writes"
    "full"
)

##
# rclone_unit_name <name>
#
# Builds the systemd user unit name for a SysKit managed mount.
#
# Parameters:
#   name    Service name without the rclone- prefix.
#
# Output:
#   Prints the unit name, for example rclone-onedrive.service.
#
rclone_unit_name() {
    local name="$1"

    printf '%s%s.service\n' "$__RCLONE_UNIT_PREFIX" "$name"
}

##
# rclone_unit_path <name>
#
# Builds the unit file path for a SysKit managed mount.
#
# Parameters:
#   name    Service name without the rclone- prefix.
#
# Output:
#   Prints the absolute unit file path.
#
rclone_unit_path() {
    local name="$1"

    printf '%s/%s\n' "$__RCLONE_UNIT_DIR" "$(rclone_unit_name "$name")"
}

##
# rclone_valid_service_name <name>
#
# Checks that a service name is safe for a unit file name and --volname.
#
# Parameters:
#   name    Service name without the rclone- prefix.
#
# Returns:
#   1 when the name contains unsupported characters.
#
rclone_valid_service_name() {
    local name="$1"

    [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]
}

##
# rclone_list_units
#
# Lists the rclone-*.service unit files in the systemd user unit directory.
# Symbolic links and non-regular files are skipped.
#
# Output:
#   Prints one unit name per line, sorted.
#
rclone_list_units() {
    local path
    local -a units=()

    for path in "$__RCLONE_UNIT_DIR/$__RCLONE_UNIT_PREFIX"*.service; do
        if [[ -f "$path" ]] && [[ ! -L "$path" ]]; then
            units+=("${path##*/}")
        fi
    done

    if (( ${#units[@]} > 0 )); then
        printf '%s\n' "${units[@]}" | sort
    fi
}

##
# rclone_valid_remote <remote>
#
# Checks that a remote specification has the form name: or name:path.
#
# Parameters:
#   remote    Remote specification, for example onedrive:/path/sub-folder.
#
# Returns:
#   1 when the specification has no remote name.
#
rclone_valid_remote() {
    local remote="$1"

    [[ "$remote" =~ ^[^:[:space:]][^:]*: ]] && [[ "$remote" != *$'\n'* ]]
}

##
# rclone_remote_exists <remote>
#
# Checks the remote name of a specification against `rclone listremotes`.
#
# Parameters:
#   remote    Remote specification, for example onedrive:/path/sub-folder.
#
# Returns:
#   1 when the remote is not configured.
#   2 when rclone is unavailable or cannot list its remotes.
#
rclone_remote_exists() {
    local remote="$1"
    local name="${remote%%:*}:"
    local configured
    local -a remotes=()

    if ! command -v rclone >/dev/null 2>&1; then
        return 2
    fi

    if ! configured="$(rclone listremotes 2>/dev/null)"; then
        return 2
    fi

    mapfile -t remotes <<<"$configured"

    for configured in "${remotes[@]}"; do
        if [[ "$configured" == "$name" ]]; then
            return 0
        fi
    done

    return 1
}

##
# rclone_valid_cache_mode <mode>
#
# Checks that a value is a supported --vfs-cache-mode.
#
# Parameters:
#   mode    Candidate cache mode.
#
# Returns:
#   1 when the mode is unsupported.
#
rclone_valid_cache_mode() {
    local mode="$1"
    local supported

    for supported in "${__RCLONE_CACHE_MODES[@]}"; do
        if [[ "$mode" == "$supported" ]]; then
            return 0
        fi
    done

    return 1
}

##
# rclone_valid_size <size>
#
# Checks that a value is an rclone size, for example 512M, 1G, or 10Gi.
#
# Parameters:
#   size    Candidate size.
#
# Returns:
#   1 when the value is not a size.
#
rclone_valid_size() {
    local size="$1"

    [[ "$size" =~ ^[0-9]+(\.[0-9]+)?([BbKkMGTP]i?)?$ ]]
}

##
# rclone_valid_duration <duration>
#
# Checks that a value is an rclone duration, for example 720h, 30d, or 1h30m.
#
# Parameters:
#   duration    Candidate duration.
#
# Returns:
#   1 when the value is not a duration.
#
rclone_valid_duration() {
    local duration="$1"

    [[ "$duration" =~ ^([0-9]+(\.[0-9]+)?(ms|s|m|h|d|w|M|y))+$ ]]
}

##
# rclone_check_directory <path>
#
# Checks that a path is a real directory the current user can write to.
#
# Parameters:
#   path    Absolute directory path.
#
# Returns:
#   1 when the path does not exist.
#   2 when the path is a symbolic link.
#   3 when the path is not a directory.
#   4 when the directory is not writable by the current user.
#
rclone_check_directory() {
    local path="$1"

    if [[ -L "$path" ]]; then
        return 2
    fi

    if [[ ! -e "$path" ]]; then
        return 1
    fi

    if [[ ! -d "$path" ]]; then
        return 3
    fi

    if [[ ! -w "$path" ]] || [[ ! -x "$path" ]]; then
        return 4
    fi
}

##
# __rclone_systemd_arg <value>
#
# Escapes a value as one systemd command-line argument. Specifier and
# variable characters are doubled; values with whitespace, quotes, or
# backslashes are wrapped in double quotes.
#
# Output:
#   Prints the escaped argument.
#
__rclone_systemd_arg() {
    local value="$1"
    local escaped="$value"

    escaped="${escaped//%/%%}"
    escaped="${escaped//\$/\$\$}"

    if [[ "$value" =~ [[:space:]\"\'\\\;] ]]; then
        escaped="${escaped//\\/\\\\}"
        escaped="${escaped//\"/\\\"}"
        escaped="\"$escaped\""
    fi

    printf '%s\n' "$escaped"
}

##
# __rclone_fusermount_path
#
# Resolves the FUSE unmount helper, preferring fusermount3.
#
# Output:
#   Prints the absolute helper path.
#
# Returns:
#   1 when neither fusermount3 nor fusermount is installed.
#
__rclone_fusermount_path() {
    command -v fusermount3 2>/dev/null || command -v fusermount 2>/dev/null
}

##
# __rclone_daemon_reload
#
# Reloads the systemd user manager so unit file changes are picked up.
#
# Returns:
#   1 when systemctl fails.
#
__rclone_daemon_reload() {
    if ! systemctl --user daemon-reload; then
        log_error "Failed to reload the systemd user manager"

        return 1
    fi
}

##
# write_rclone_unit <name> <remote> <mount_dir> <cache_mode> <cache_dir> <max_size> <max_age>
#
# Writes a systemd user unit that mounts an rclone remote, then reloads the
# systemd user manager. An existing unit file is never replaced.
#
# Parameters:
#   name          Service name without the rclone- prefix; also --volname.
#   remote        Remote specification, for example onedrive:/path.
#   mount_dir     Absolute local mount directory.
#   cache_mode    --vfs-cache-mode value.
#   cache_dir     Absolute --cache-dir directory.
#   max_size      --vfs-cache-max-size value.
#   max_age       --vfs-cache-max-age value.
#
# Returns:
#   1 when a dependency is missing, the unit exists, or writing fails.
#
write_rclone_unit() {
    local name="$1"
    local remote="$2"
    local mount_dir="$3"
    local cache_mode="$4"
    local cache_dir="$5"
    local max_size="$6"
    local max_age="$7"
    local unit_path
    local rclone_path
    local fusermount_path
    local tmp_file
    local exec_start
    local exec_stop

    unit_path="$(rclone_unit_path "$name")"

    if ! rclone_path="$(command -v rclone 2>/dev/null)"; then
        log_error "rclone is required before an auto mount service can be created"

        return 1
    fi

    if ! fusermount_path="$(__rclone_fusermount_path)"; then
        log_error "fusermount3 or fusermount is required to unmount rclone remotes"

        return 1
    fi

    if [[ -e "$unit_path" ]] || [[ -L "$unit_path" ]]; then
        log_error "Unit file already exists: $unit_path"

        return 1
    fi

    if ! mkdir -p -- "$__RCLONE_UNIT_DIR"; then
        log_error "Failed to create directory: $__RCLONE_UNIT_DIR"

        return 1
    fi

    exec_start="$(__rclone_systemd_arg "$rclone_path") mount"
    exec_start+=" $(__rclone_systemd_arg "$remote")"
    exec_start+=" $(__rclone_systemd_arg "$mount_dir")"
    exec_start+=" --vfs-cache-mode $(__rclone_systemd_arg "$cache_mode")"
    exec_start+=" --cache-dir $(__rclone_systemd_arg "$cache_dir")"
    exec_start+=" --vfs-cache-max-size $(__rclone_systemd_arg "$max_size")"
    exec_start+=" --vfs-cache-max-age $(__rclone_systemd_arg "$max_age")"
    exec_start+=" --volname $(__rclone_systemd_arg "$name")"

    exec_stop="$(__rclone_systemd_arg "$fusermount_path") -u"
    exec_stop+=" $(__rclone_systemd_arg "$mount_dir")"

    if ! tmp_file="$(mktemp "$__RCLONE_UNIT_DIR/.${__RCLONE_UNIT_PREFIX}XXXXXX")"; then
        log_error "Failed to create temporary unit file in $__RCLONE_UNIT_DIR"

        return 1
    fi

    # network-online.target exists only in the system manager; a user unit
    # cannot order against it, so After=/Wants= on it are silently ignored.
    # Restart=on-failure covers a network that is not ready at login.
    if ! printf '%s\n' \
        "# Managed by SysKit (cli/rclone)" \
        "[Unit]" \
        "Description=rclone mount $name" \
        "# No After=/Wants=network-online.target: that target belongs to the" \
        "# system manager and is not visible to user services, so it would be" \
        "# ignored. Restart=on-failure retries when the network is not ready yet." \
        "# Convert to a system service (with User=) to really wait for the network." \
        "" \
        "[Service]" \
        "Type=notify" \
        "ExecStart=$exec_start" \
        "ExecStop=$exec_stop" \
        "Restart=on-failure" \
        "" \
        "[Install]" \
        "WantedBy=default.target" >"$tmp_file" ||
        ! chmod 0644 -- "$tmp_file" ||
        ! mv -n -- "$tmp_file" "$unit_path"; then
        log_error "Failed to write unit file: $unit_path"
        rm -f -- "$tmp_file"

        return 1
    fi

    if [[ -e "$tmp_file" ]]; then
        log_error "Unit file already exists: $unit_path"
        rm -f -- "$tmp_file"

        return 1
    fi

    log_info "Created $unit_path"
    __rclone_daemon_reload
}

##
# enable_rclone_unit <name>
#
# Enables a SysKit managed mount at login and starts it now.
#
# Parameters:
#   name    Service name without the rclone- prefix.
#
# Returns:
#   1 when systemctl fails.
#
enable_rclone_unit() {
    local name="$1"
    local unit

    unit="$(rclone_unit_name "$name")"

    if ! systemctl --user enable --now "$unit"; then
        log_error "Failed to enable $unit; inspect it with: journalctl --user -u $unit"

        return 1
    fi

    log_info "Enabled and started $unit"
}

##
# remove_rclone_unit <unit>
#
# Stops and disables a SysKit managed mount, removes its unit file, and
# reloads the systemd user manager.
#
# Parameters:
#   unit    Unit name, for example rclone-onedrive.service.
#
# Returns:
#   1 when the unit name is invalid, or removal or reloading fails.
#
remove_rclone_unit() {
    local unit="$1"
    local name="${unit#"$__RCLONE_UNIT_PREFIX"}"
    local unit_path

    name="${name%.service}"

    if [[ "$unit" != "$(rclone_unit_name "$name")" ]] ||
        ! rclone_valid_service_name "$name"; then
        log_error "Invalid rclone unit name: $unit"

        return 1
    fi

    unit_path="$(rclone_unit_path "$name")"

    if [[ ! -e "$unit_path" ]] && [[ ! -L "$unit_path" ]]; then
        log_warn "Unit file does not exist: $unit_path"

        return 0
    fi

    if ! systemctl --user disable --now "$unit"; then
        log_warn "Failed to stop or disable $unit; removing its unit file anyway"
    fi

    if ! rm -f -- "$unit_path"; then
        log_error "Failed to remove unit file: $unit_path"

        return 1
    fi

    log_info "Removed $unit_path"
    __rclone_daemon_reload
}

##
# rclone_unit_enabled_state <unit>
#
# Reads whether a unit is enabled in the systemd user manager.
#
# Parameters:
#   unit    Unit name, for example rclone-onedrive.service.
#
# Output:
#   Prints the systemctl is-enabled state, or unknown.
#
rclone_unit_enabled_state() {
    local unit="$1"
    local state

    state="$(systemctl --user is-enabled "$unit" 2>/dev/null)" || true
    printf '%s\n' "${state:-unknown}"
}

##
# rclone_unit_active_state <unit>
#
# Reads whether a unit is running in the systemd user manager.
#
# Parameters:
#   unit    Unit name, for example rclone-onedrive.service.
#
# Output:
#   Prints the systemctl is-active state, or unknown.
#
rclone_unit_active_state() {
    local unit="$1"
    local state

    state="$(systemctl --user is-active "$unit" 2>/dev/null)" || true
    printf '%s\n' "${state:-unknown}"
}
