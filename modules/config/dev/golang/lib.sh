if (( ${__SYSKIT_GOLANG_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_GOLANG_CONFIG_LIB_LOADED=1

source "$COMMON_LIB/checksum.sh"

readonly __GOLANG_STATE_DIR="$HOME/.local/state/syskit/dev/golang"
readonly __GOLANG_GOBIN_FILE="$__GOLANG_STATE_DIR/gobin"
readonly __GOLANG_PROFILE_FILE="/etc/profile.d/99-dev-golang.sh"
readonly __GOLANG_PROFILE_PAYLOAD="99-dev-golang.sh"
readonly __GOLANG_PROFILE_MARKER="# Managed by SysKit (dev/golang)"
readonly __GOLANG_MISE_SETTING="go.set_gobin"

##
# read_golang_gobin_state
#
# Reads and validates the persisted GOBIN override.
#
# Output:
#   Prints the persisted absolute GOBIN directory.
#
# Returns:
#   1 when the state file is missing, symbolic, unreadable, malformed, or
#   contains a relative path.
#
read_golang_gobin_state() {
    local -a lines=()

    if [[ ! -f "$__GOLANG_GOBIN_FILE" ]] ||
        [[ -L "$__GOLANG_GOBIN_FILE" ]] ||
        [[ ! -r "$__GOLANG_GOBIN_FILE" ]]; then
        return 1
    fi

    if ! mapfile -t lines <"$__GOLANG_GOBIN_FILE"; then
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

##
# write_golang_gobin_state <gobin>
#
# Atomically persists the GOBIN override for the current user.
#
# Parameters:
#   gobin    Absolute GOBIN directory.
#
# Returns:
#   1 when the state directory or file cannot be created safely.
#
write_golang_gobin_state() {
    local gobin="$1"
    local state_tmp

    if [[ -L "$__GOLANG_STATE_DIR" ]] ||
        { [[ -e "$__GOLANG_STATE_DIR" ]] && [[ ! -d "$__GOLANG_STATE_DIR" ]]; }; then
        log_error "Invalid Go state directory: $__GOLANG_STATE_DIR"

        return 1
    fi

    if ! mkdir -p -- "$__GOLANG_STATE_DIR"; then
        log_error "Failed to create Go state directory: $__GOLANG_STATE_DIR"

        return 1
    fi

    if ! chmod 0700 -- "$__GOLANG_STATE_DIR"; then
        log_error "Failed to secure Go state directory: $__GOLANG_STATE_DIR"

        return 1
    fi

    if [[ -L "$__GOLANG_GOBIN_FILE" ]]; then
        if ! rm -f -- "$__GOLANG_GOBIN_FILE"; then
            log_error "Failed to replace symbolic Go state: $__GOLANG_GOBIN_FILE"

            return 1
        fi
    elif [[ -e "$__GOLANG_GOBIN_FILE" ]] && [[ ! -f "$__GOLANG_GOBIN_FILE" ]]; then
        log_error "Go state path is not a regular file: $__GOLANG_GOBIN_FILE"

        return 1
    fi

    if ! state_tmp="$(mktemp "$__GOLANG_GOBIN_FILE.XXXXXX")"; then
        log_error "Failed to create temporary GOBIN state"

        return 1
    fi

    if ! printf '%s\n' "$gobin" >"$state_tmp"; then
        log_error "Failed to write temporary GOBIN state"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! chmod 0600 -- "$state_tmp"; then
        log_error "Failed to secure temporary GOBIN state: $state_tmp"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! mv -f -- "$state_tmp" "$__GOLANG_GOBIN_FILE"; then
        log_error "Failed to install GOBIN state file: $__GOLANG_GOBIN_FILE"
        rm -f -- "$state_tmp"

        return 1
    fi
}

##
# remove_golang_gobin_state
#
# Removes the GOBIN override and prunes empty SysKit state directories.
#
# Returns:
#   1 when the state file cannot be removed.
#
remove_golang_gobin_state() {
    local dev_dir
    local syskit_dir
    local dir

    dev_dir="${__GOLANG_STATE_DIR%/golang}"
    syskit_dir="${dev_dir%/dev}"

    if [[ -e "$__GOLANG_GOBIN_FILE" ]] || [[ -L "$__GOLANG_GOBIN_FILE" ]]; then
        if ! rm -f -- "$__GOLANG_GOBIN_FILE"; then
            log_error "Failed to remove GOBIN state file: $__GOLANG_GOBIN_FILE"

            return 1
        fi
    fi

    for dir in "$__GOLANG_STATE_DIR" "$dev_dir" "$syskit_dir"; do
        if [[ ! -d "$dir" ]] || [[ -L "$dir" ]]; then
            break
        fi

        rmdir -- "$dir" 2>/dev/null || break
    done
}

##
# golang_profile_state
#
# Resolves the state of the system-wide GOBIN profile script.
#
# Returns:
#   1 when the profile script does not exist.
#   2 when the path exists but is not a regular SysKit-managed file.
#
golang_profile_state() {
    local first_line=""

    if [[ ! -e "$__GOLANG_PROFILE_FILE" ]] && [[ ! -L "$__GOLANG_PROFILE_FILE" ]]; then
        return 1
    fi

    if [[ -L "$__GOLANG_PROFILE_FILE" ]] ||
        [[ ! -f "$__GOLANG_PROFILE_FILE" ]] ||
        [[ ! -r "$__GOLANG_PROFILE_FILE" ]]; then
        return 2
    fi

    IFS= read -r first_line <"$__GOLANG_PROFILE_FILE" || true
    [[ "$first_line" == "$__GOLANG_PROFILE_MARKER" ]] || return 2
}

##
# golang_profile_payload
#
# Resolves and validates the bundled profile script payload.
#
# Output:
#   Prints the payload path.
#
# Returns:
#   1 when the payload is missing, symbolic, unreadable, or does not start
#   with the SysKit marker.
#
golang_profile_payload() {
    local source="${CONFIG_MODULE_PAYLOAD:-}/$__GOLANG_PROFILE_PAYLOAD"
    local first_line=""

    if [[ -z "${CONFIG_MODULE_PAYLOAD:-}" ]] ||
        [[ -L "$source" ]] ||
        [[ ! -f "$source" ]] ||
        [[ ! -r "$source" ]]; then
        log_error "Go profile payload is unavailable: $source"

        return 1
    fi

    IFS= read -r first_line <"$source" || true
    if [[ "$first_line" != "$__GOLANG_PROFILE_MARKER" ]]; then
        log_error "Go profile payload does not start with '$__GOLANG_PROFILE_MARKER': $source"

        return 1
    fi

    printf '%s\n' "$source"
}

##
# golang_profile_current
#
# Compares the installed profile script with the bundled payload.
#
# Returns:
#   1 when the installed script differs from the payload.
#   2 when the payload is invalid or either file cannot be checksummed.
#
golang_profile_current() {
    local source
    local status=0

    source="$(golang_profile_payload)" || return 2
    checksums_match "$source" "$__GOLANG_PROFILE_FILE" || status=$?

    case "$status" in
        0 | 1)
            return "$status"
            ;;
    esac

    return 2
}

##
# write_golang_profile
#
# Installs or updates the managed profile script that exports GOBIN for login
# shells.
#
# Returns:
#   1 when the payload is invalid, an unmanaged file occupies the target, or
#   the write fails.
#
write_golang_profile() {
    local source
    local state=0

    golang_profile_state || state=$?

    if (( state == 2 )); then
        log_error "Refusing to overwrite unmanaged file: $__GOLANG_PROFILE_FILE"

        return 1
    fi

    source="$(golang_profile_payload)" || return $?

    log_info "Administrator privileges are required to write $__GOLANG_PROFILE_FILE"

    if ! sudo install -Dm0644 -- "$source" "$__GOLANG_PROFILE_FILE"; then
        log_error "Failed to write $__GOLANG_PROFILE_FILE"

        return 1
    fi

    log_info "Installed $__GOLANG_PROFILE_FILE; log out and back in to apply it"
}

##
# remove_golang_profile
#
# Removes the managed profile script.
#
# Returns:
#   1 when the target is unmanaged or the removal fails.
#
remove_golang_profile() {
    local state=0

    golang_profile_state || state=$?

    if (( state == 1 )); then
        log_info "$__GOLANG_PROFILE_FILE is not installed"

        return 0
    fi

    if (( state == 2 )); then
        log_error "Refusing to remove unmanaged file: $__GOLANG_PROFILE_FILE"

        return 1
    fi

    log_info "Administrator privileges are required to remove $__GOLANG_PROFILE_FILE"

    if ! sudo rm -f -- "$__GOLANG_PROFILE_FILE"; then
        log_error "Failed to remove $__GOLANG_PROFILE_FILE"

        return 1
    fi

    log_info "Removed $__GOLANG_PROFILE_FILE; log out and back in to apply it"
}

##
# mise_installed
#
# Returns:
#   1 when the mise command is unavailable.
#
mise_installed() {
    command -v mise >/dev/null 2>&1
}

##
# require_mise
#
# Ensures mise is available before managing its settings.
#
# Returns:
#   1 when the mise command is unavailable.
#
require_mise() {
    if ! mise_installed; then
        log_error "Mise is not installed; cannot manage $__GOLANG_MISE_SETTING"

        return 1
    fi
}

##
# set_mise_go_set_gobin <value>
#
# Writes go.set_gobin into the global Mise configuration. Runs from / so a
# project mise.toml never receives or masks the setting.
#
# Parameters:
#   value    true or false.
#
# Returns:
#   1 when the value is invalid, mise is unavailable, or the write fails.
#
set_mise_go_set_gobin() {
    local value="$1"

    if [[ "$value" != "true" ]] && [[ "$value" != "false" ]]; then
        log_error "Invalid $__GOLANG_MISE_SETTING value: $value"

        return 1
    fi

    require_mise || return $?

    if ! (cd / && mise settings set "$__GOLANG_MISE_SETTING" "$value"); then
        log_error "Failed to set Mise $__GOLANG_MISE_SETTING=$value"

        return 1
    fi

    log_info "Set Mise $__GOLANG_MISE_SETTING=$value"
}

##
# unset_mise_go_set_gobin
#
# Removes go.set_gobin from the global Mise configuration so Mise uses its
# default (set GOBIN only when it is not already set).
#
# Returns:
#   1 when mise is unavailable or the removal fails.
#
unset_mise_go_set_gobin() {
    require_mise || return $?

    if ! (cd / && mise settings unset "$__GOLANG_MISE_SETTING"); then
        log_error "Failed to reset Mise $__GOLANG_MISE_SETTING"

        return 1
    fi

    log_info "Reset Mise $__GOLANG_MISE_SETTING to its default"
}

##
# read_mise_go_set_gobin
#
# Reads the effective go.set_gobin value outside any project directory.
#
# Output:
#   Prints true, false, or default when the setting is not set.
#
# Returns:
#   1 when mise is unavailable.
#
read_mise_go_set_gobin() {
    local value

    mise_installed || return 1

    if ! value="$(cd / && mise settings get "$__GOLANG_MISE_SETTING" 2>/dev/null)"; then
        value="default"
    fi

    case "$value" in
        true | false) ;;
        *) value="default" ;;
    esac

    printf '%s\n' "$value"
}
