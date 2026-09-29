if (( ${__SYSKIT_MISE_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_MISE_CONFIG_LIB_LOADED=1

readonly __MISE_STATE_DIR="$HOME/.local/state/syskit/dev/mise"
readonly __MISE_DATA_DIR_FILE="$__MISE_STATE_DIR/data-dir"

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
        log_error "Invalid SDKMAN! state directory: $__MISE_STATE_DIR"

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
            log_error "Failed to replace symbolic SDKMAN! state: $__MISE_DATA_DIR_FILE"

            return 1
        fi
    elif [[ -e "$__MISE_DATA_DIR_FILE" ]] && [[ ! -f "$__MISE_DATA_DIR_FILE" ]]; then
        log_error "SDKMAN! state path is not a regular file: $__MISE_DATA_DIR_FILE"

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