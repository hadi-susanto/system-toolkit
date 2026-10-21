if (( ${__SYSKIT_MISE_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_MISE_CONFIG_LIB_LOADED=1

readonly __MISE_STATE_DIR="$HOME/.local/state/syskit/dev/mise"
readonly __MISE_DATA_DIR_FILE="$__MISE_STATE_DIR/data-dir"
readonly __MISE_PROFILE_FILE="/etc/profile.d/99-dev-mise.sh"
readonly __MISE_PROFILE_MARKER="# Managed by SysKit (dev/mise)"

##
# read_mise_data_dir_state
#
# Reads and validates the persisted Mise data directory.
#
# Output:
#   Prints the persisted absolute data directory.
#
# Returns:
#   1 when the state file is missing, symbolic, unreadable, malformed, or
#   contains a relative path.
#
read_mise_data_dir_state() {
    local -a lines=()

    if [[ ! -f "$__MISE_DATA_DIR_FILE" ]] ||
        [[ -L "$__MISE_DATA_DIR_FILE" ]] ||
        [[ ! -r "$__MISE_DATA_DIR_FILE" ]]; then
        return 1
    fi

    if ! mapfile -t lines <"$__MISE_DATA_DIR_FILE"; then
        return 1
    fi

    if (( ${#lines[@]} != 1 )) ||
        [[ -z "${lines[0]}" ]] ||
        [[ "${lines[0]}" != /* ]] ||
        [[ "${lines[0]}" == *$'\r'* ]]; then
        return 1
    fi

    printf '%s\n' "${lines[0]}"
}

write_mise_data_dir_state() {
    local data_dir="$1"
    local state_tmp

    if [[ -L "$__MISE_STATE_DIR" ]] ||
        { [[ -e "$__MISE_STATE_DIR" ]] && [[ ! -d "$__MISE_STATE_DIR" ]]; }; then
        log_error "Invalid Mise state directory: $__MISE_STATE_DIR"

        return 1
    fi

    if ! mkdir -p -- "$__MISE_STATE_DIR"; then
        log_error "Failed to create Mise state directory: $__MISE_STATE_DIR"

        return 1
    fi

    if ! chmod 0700 -- "$__MISE_STATE_DIR"; then
        log_error "Failed to secure Mise state directory: $__MISE_STATE_DIR"

        return 1
    fi

    if [[ -L "$__MISE_DATA_DIR_FILE" ]]; then
        if ! rm -f -- "$__MISE_DATA_DIR_FILE"; then
            log_error "Failed to replace symbolic Mise state: $__MISE_DATA_DIR_FILE"

            return 1
        fi
    elif [[ -e "$__MISE_DATA_DIR_FILE" ]] && [[ ! -f "$__MISE_DATA_DIR_FILE" ]]; then
        log_error "Mise state path is not a regular file: $__MISE_DATA_DIR_FILE"

        return 1
    fi

    if ! state_tmp="$(mktemp "$__MISE_DATA_DIR_FILE.XXXXXX")"; then
        log_error "Failed to create temporary Mise data-dir state"

        return 1
    fi

    if ! printf '%s\n' "$data_dir" >"$state_tmp"; then
        log_error "Failed to write temporary Mise data-dir state"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! chmod 0600 -- "$state_tmp"; then
        log_error "Failed to secure temporary Mise data-dir state: $state_tmp"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! mv -f -- "$state_tmp" "$__MISE_DATA_DIR_FILE"; then
        log_error "Failed to install Mise data-dir state file: $__MISE_DATA_DIR_FILE"
        rm -f -- "$state_tmp"

        return 1
    fi
}

remove_mise_data_dir_state() {
    local dev_dir
    local syskit_dir
    local dir

    dev_dir="${__MISE_STATE_DIR%/mise}"
    syskit_dir="${dev_dir%/dev}"

    if [[ -e "$__MISE_DATA_DIR_FILE" ]] || [[ -L "$__MISE_DATA_DIR_FILE" ]]; then
        if ! rm -f -- "$__MISE_DATA_DIR_FILE"; then
            log_error "Failed to remove Mise data-dir state file: $__MISE_DATA_DIR_FILE"

            return 1
        fi
    fi

    for dir in "$__MISE_STATE_DIR" "$dev_dir" "$syskit_dir"; do
        if [[ ! -d "$dir" ]] || [[ -L "$dir" ]]; then
            break
        fi

        rmdir -- "$dir" 2>/dev/null || break
    done
}

##
# mise_profile_state
#
# Resolves the state of the system-wide Mise shims profile script.
#
# Returns:
#   1 when the profile script does not exist.
#   2 when the path exists but is not a regular SysKit-managed file.
#
mise_profile_state() {
    local first_line=""

    if [[ ! -e "$__MISE_PROFILE_FILE" ]] && [[ ! -L "$__MISE_PROFILE_FILE" ]]; then
        return 1
    fi

    if [[ -L "$__MISE_PROFILE_FILE" ]] ||
        [[ ! -f "$__MISE_PROFILE_FILE" ]] ||
        [[ ! -r "$__MISE_PROFILE_FILE" ]]; then
        return 2
    fi

    IFS= read -r first_line <"$__MISE_PROFILE_FILE" || true
    [[ "$first_line" == "$__MISE_PROFILE_MARKER" ]] || return 2
}

##
# read_mise_profile_shims_dir
#
# Reads the shims directory recorded in the managed profile script.
#
# Output:
#   Prints the recorded shims directory as written (it may reference $HOME).
#
# Returns:
#   1 when the profile script is not managed or has no shims directory.
#
read_mise_profile_shims_dir() {
    local line

    mise_profile_state || return 1

    while IFS= read -r line; do
        if [[ "$line" =~ ^__syskit_mise_shims=\"(.*)\"$ ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"

            return 0
        fi
    done <"$__MISE_PROFILE_FILE"

    return 1
}

##
# resolve_mise_shims_dir
#
# Resolves the shims directory to record in the profile script. Uses the
# persisted data-dir override when present; otherwise prints the Mise default
# with a literal $HOME so it resolves per user at login.
#
# Output:
#   Prints the shims directory.
#
# Returns:
#   1 when the data-dir override contains characters that are unsafe inside a
#   double-quoted shell string.
#
resolve_mise_shims_dir() {
    local data_dir

    if ! data_dir="$(read_mise_data_dir_state)"; then
        # shellcheck disable=SC2016 # $HOME must stay literal for login shells
        printf '%s\n' '$HOME/.local/share/mise/shims'

        return 0
    fi

    if [[ "$data_dir" == *[\"\$\`\\]* ]]; then
        log_error "Mise data directory contains characters unsupported in a profile script: $data_dir"

        return 1
    fi

    printf '%s/shims\n' "${data_dir%/}"
}

##
# render_mise_profile <shims_dir>
#
# Output:
#   Prints the POSIX sh profile script that prepends <shims_dir> to PATH.
#
render_mise_profile() {
    local shims_dir="$1"

    printf '%s\n' "$__MISE_PROFILE_MARKER"
    printf '__syskit_mise_shims="%s"\n' "$shims_dir"
    cat <<'PROFILE'
if [ -d "$__syskit_mise_shims" ]; then
    case ":$PATH:" in
        *":$__syskit_mise_shims:"*) ;;
        *) PATH="$__syskit_mise_shims:$PATH"; export PATH ;;
    esac
fi
unset __syskit_mise_shims
PROFILE
}

##
# write_mise_profile <shims_dir>
#
# Installs the managed profile script that adds Mise shims to PATH for login
# shells.
#
# Returns:
#   1 when an unmanaged file occupies the target or the write fails.
#
write_mise_profile() {
    local shims_dir="$1"
    local tmp
    local state=0

    mise_profile_state || state=$?

    if (( state == 2 )); then
        log_error "Refusing to overwrite unmanaged file: $__MISE_PROFILE_FILE"

        return 1
    fi

    if ! tmp="$(mktemp)"; then
        log_error "Failed to create a temporary file"

        return 1
    fi

    if ! render_mise_profile "$shims_dir" >"$tmp"; then
        rm -f -- "$tmp"
        log_error "Failed to render the Mise profile script"

        return 1
    fi

    log_info "Administrator privileges are required to write $__MISE_PROFILE_FILE"

    if ! sudo install -Dm0644 -- "$tmp" "$__MISE_PROFILE_FILE"; then
        rm -f -- "$tmp"
        log_error "Failed to write $__MISE_PROFILE_FILE"

        return 1
    fi

    rm -f -- "$tmp"
    log_info "Installed $__MISE_PROFILE_FILE; log out and back in to apply it"
}

##
# remove_mise_profile
#
# Removes the managed profile script.
#
# Returns:
#   1 when the target is unmanaged or the removal fails.
#
remove_mise_profile() {
    local state=0

    mise_profile_state || state=$?

    if (( state == 1 )); then
        log_info "$__MISE_PROFILE_FILE is not installed"

        return 0
    fi

    if (( state == 2 )); then
        log_error "Refusing to remove unmanaged file: $__MISE_PROFILE_FILE"

        return 1
    fi

    log_info "Administrator privileges are required to remove $__MISE_PROFILE_FILE"

    if ! sudo rm -f -- "$__MISE_PROFILE_FILE"; then
        log_error "Failed to remove $__MISE_PROFILE_FILE"

        return 1
    fi

    log_info "Removed $__MISE_PROFILE_FILE; log out and back in to apply it"
}
