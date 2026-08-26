if (( ${__SYSKIT_SDKMAN_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_SDKMAN_CONFIG_LIB_LOADED=1

readonly __SDKMAN_STATE_DIR="$HOME/.local/state/syskit/dev/sdkman"
readonly __SDKMAN_STATE_FILE="$__SDKMAN_STATE_DIR/install-dir"

##
# resolve_sdkman_install_dir
#
# Resolves SDKMAN_DIR, falling back to SDKMAN!'s default installation path.
#
# Output:
#   Prints an absolute SDKMAN! installation directory without trailing slashes.
#
# Returns:
#   1 when the resolved path is empty, relative, or contains a line break.
#
resolve_sdkman_install_dir() {
    local install_dir="${SDKMAN_DIR:-$HOME/.sdkman}"

    if [[ -z "$install_dir" ]] ||
        [[ "$install_dir" != /* ]] ||
        [[ "$install_dir" == *$'\n'* ]] ||
        [[ "$install_dir" == *$'\r'* ]]; then
        return 1
    fi

    while [[ "$install_dir" != "/" ]] && [[ "$install_dir" == */ ]]; do
        install_dir="${install_dir%/}"
    done

    printf '%s\n' "$install_dir"
}

##
# sdkman_installation_valid <install_dir>
#
# Checks whether an SDKMAN! installation has a readable initialization file.
#
# Parameters:
#   install_dir    Absolute SDKMAN! installation directory.
#
# Returns:
#   1 when the initialization file is missing, unreadable, or not regular.
#
sdkman_installation_valid() {
    local install_dir="$1"
    local init_file="$install_dir/bin/sdkman-init.sh"

    [[ -f "$init_file" ]] && [[ -r "$init_file" ]]
}

##
# read_sdkman_state
#
# Reads and validates the persisted SDKMAN! installation directory.
#
# Output:
#   Prints the persisted absolute installation directory.
#
# Returns:
#   1 when the state file is missing, symbolic, unreadable, malformed, or
#   contains a relative path.
#
read_sdkman_state() {
    local -a lines=()

    if [[ ! -f "$__SDKMAN_STATE_FILE" ]] ||
        [[ -L "$__SDKMAN_STATE_FILE" ]] ||
        [[ ! -r "$__SDKMAN_STATE_FILE" ]]; then
        return 1
    fi

    if ! mapfile -t lines <"$__SDKMAN_STATE_FILE"; then
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
# write_sdkman_state <install_dir>
#
# Atomically persists the SDKMAN! installation directory.
#
# Parameters:
#   install_dir    Valid absolute SDKMAN! installation directory.
#
# Returns:
#   1 when the state directory or file cannot be created safely.
#
write_sdkman_state() {
    local install_dir="$1"
    local state_tmp

    if [[ -L "$__SDKMAN_STATE_DIR" ]] ||
        { [[ -e "$__SDKMAN_STATE_DIR" ]] && [[ ! -d "$__SDKMAN_STATE_DIR" ]]; }; then
        log_error "Invalid SDKMAN! state directory: $__SDKMAN_STATE_DIR"

        return 1
    fi

    if ! mkdir -p -- "$__SDKMAN_STATE_DIR"; then
        log_error "Failed to create SDKMAN! state directory: $__SDKMAN_STATE_DIR"

        return 1
    fi

    if ! chmod 0700 -- "$__SDKMAN_STATE_DIR"; then
        log_error "Failed to secure SDKMAN! state directory: $__SDKMAN_STATE_DIR"

        return 1
    fi

    if [[ -L "$__SDKMAN_STATE_FILE" ]]; then
        if ! rm -f -- "$__SDKMAN_STATE_FILE"; then
            log_error "Failed to replace symbolic SDKMAN! state: $__SDKMAN_STATE_FILE"

            return 1
        fi
    elif [[ -e "$__SDKMAN_STATE_FILE" ]] && [[ ! -f "$__SDKMAN_STATE_FILE" ]]; then
        log_error "SDKMAN! state path is not a regular file: $__SDKMAN_STATE_FILE"

        return 1
    fi

    if ! state_tmp="$(mktemp "$__SDKMAN_STATE_FILE.XXXXXX")"; then
        log_error "Failed to create temporary SDKMAN! state"

        return 1
    fi

    if ! printf '%s\n' "$install_dir" >"$state_tmp"; then
        log_error "Failed to write temporary SDKMAN! state"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! chmod 0600 -- "$state_tmp"; then
        log_error "Failed to secure temporary SDKMAN! state: $state_tmp"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! mv -f -- "$state_tmp" "$__SDKMAN_STATE_FILE"; then
        log_error "Failed to install SDKMAN! state file: $__SDKMAN_STATE_FILE"
        rm -f -- "$state_tmp"

        return 1
    fi
}

##
# remove_sdkman_state
#
# Removes the SDKMAN! state file and any resulting empty SysKit state
# directories owned by this module.
#
# Returns:
#   1 when the state file cannot be removed.
#
remove_sdkman_state() {
    local dev_dir
    local syskit_dir
    local dir

    dev_dir="${__SDKMAN_STATE_DIR%/sdkman}"
    syskit_dir="${dev_dir%/dev}"

    if [[ -e "$__SDKMAN_STATE_FILE" ]] || [[ -L "$__SDKMAN_STATE_FILE" ]]; then
        if ! rm -f -- "$__SDKMAN_STATE_FILE"; then
            log_error "Failed to remove SDKMAN! state file: $__SDKMAN_STATE_FILE"

            return 1
        fi
    fi

    for dir in "$__SDKMAN_STATE_DIR" "$dev_dir" "$syskit_dir"; do
        if [[ ! -d "$dir" ]] || [[ -L "$dir" ]]; then
            break
        fi

        rmdir -- "$dir" 2>/dev/null || break
    done
}
