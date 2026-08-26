if (( ${__SYSKIT_POWERLEVEL10K_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_POWERLEVEL10K_CONFIG_LIB_LOADED=1

readonly __POWERLEVEL10K_STATE_DIR="$HOME/.local/state/syskit/term/power-level-10k"
readonly __POWERLEVEL10K_STATE_FILE="$__POWERLEVEL10K_STATE_DIR/install-dir"

##
# resolve_powerlevel10k_install_dir
#
# Resolves POWERLEVEL10K_INSTALL_DIR.
#
# Output:
#   Prints an absolute Powerlevel10k installation directory without trailing
#   slashes.
#
# Returns:
#   1 when the path is empty, relative, or contains a line break.
#
resolve_powerlevel10k_install_dir() {
    local install_dir="${POWERLEVEL10K_INSTALL_DIR:-}"

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
# powerlevel10k_installation_valid <install_dir>
#
# Checks whether a Powerlevel10k installation has a readable theme file.
#
# Parameters:
#   install_dir    Absolute Powerlevel10k installation directory.
#
# Returns:
#   1 when the theme file is missing, unreadable, or not regular.
#
powerlevel10k_installation_valid() {
    local install_dir="$1"
    local theme_file="$install_dir/powerlevel10k.zsh-theme"

    [[ -f "$theme_file" ]] && [[ -r "$theme_file" ]]
}

##
# read_powerlevel10k_state
#
# Reads and validates the persisted Powerlevel10k installation directory.
#
# Output:
#   Prints the persisted absolute installation directory.
#
# Returns:
#   1 when the state file is missing, symbolic, unreadable, malformed, or
#   contains a relative path.
#
read_powerlevel10k_state() {
    local -a lines=()

    if [[ ! -f "$__POWERLEVEL10K_STATE_FILE" ]] ||
        [[ -L "$__POWERLEVEL10K_STATE_FILE" ]] ||
        [[ ! -r "$__POWERLEVEL10K_STATE_FILE" ]]; then
        return 1
    fi

    if ! mapfile -t lines <"$__POWERLEVEL10K_STATE_FILE"; then
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
# write_powerlevel10k_state <install_dir>
#
# Atomically persists the Powerlevel10k installation directory.
#
# Parameters:
#   install_dir    Valid absolute Powerlevel10k installation directory.
#
# Returns:
#   1 when the state directory or file cannot be created safely.
#
write_powerlevel10k_state() {
    local install_dir="$1"
    local state_tmp

    if [[ -L "$__POWERLEVEL10K_STATE_DIR" ]] ||
        { [[ -e "$__POWERLEVEL10K_STATE_DIR" ]] && [[ ! -d "$__POWERLEVEL10K_STATE_DIR" ]]; }; then
        log_error "Invalid Powerlevel10k state directory: $__POWERLEVEL10K_STATE_DIR"

        return 1
    fi

    if ! mkdir -p -- "$__POWERLEVEL10K_STATE_DIR"; then
        log_error "Failed to create Powerlevel10k state directory: $__POWERLEVEL10K_STATE_DIR"

        return 1
    fi

    if ! chmod 0700 -- "$__POWERLEVEL10K_STATE_DIR"; then
        log_error "Failed to secure Powerlevel10k state directory: $__POWERLEVEL10K_STATE_DIR"

        return 1
    fi

    if [[ -L "$__POWERLEVEL10K_STATE_FILE" ]]; then
        if ! rm -f -- "$__POWERLEVEL10K_STATE_FILE"; then
            log_error "Failed to replace symbolic Powerlevel10k state: $__POWERLEVEL10K_STATE_FILE"

            return 1
        fi
    elif [[ -e "$__POWERLEVEL10K_STATE_FILE" ]] &&
        [[ ! -f "$__POWERLEVEL10K_STATE_FILE" ]]; then
        log_error "Powerlevel10k state path is not a regular file: $__POWERLEVEL10K_STATE_FILE"

        return 1
    fi

    if ! state_tmp="$(mktemp "$__POWERLEVEL10K_STATE_FILE.XXXXXX")"; then
        log_error "Failed to create temporary Powerlevel10k state"

        return 1
    fi

    if ! printf '%s\n' "$install_dir" >"$state_tmp"; then
        log_error "Failed to write temporary Powerlevel10k state"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! chmod 0600 -- "$state_tmp"; then
        log_error "Failed to secure temporary Powerlevel10k state: $state_tmp"
        rm -f -- "$state_tmp"

        return 1
    fi

    if ! mv -f -- "$state_tmp" "$__POWERLEVEL10K_STATE_FILE"; then
        log_error "Failed to install Powerlevel10k state file: $__POWERLEVEL10K_STATE_FILE"
        rm -f -- "$state_tmp"

        return 1
    fi
}

##
# remove_powerlevel10k_state
#
# Removes the Powerlevel10k state file and any resulting empty SysKit state
# directories owned by this module.
#
# Returns:
#   1 when the state file cannot be removed.
#
remove_powerlevel10k_state() {
    local term_dir
    local syskit_dir
    local dir

    term_dir="${__POWERLEVEL10K_STATE_DIR%/power-level-10k}"
    syskit_dir="${term_dir%/term}"

    if [[ -e "$__POWERLEVEL10K_STATE_FILE" ]] ||
        [[ -L "$__POWERLEVEL10K_STATE_FILE" ]]; then
        if ! rm -f -- "$__POWERLEVEL10K_STATE_FILE"; then
            log_error "Failed to remove Powerlevel10k state file: $__POWERLEVEL10K_STATE_FILE"

            return 1
        fi
    fi

    for dir in "$__POWERLEVEL10K_STATE_DIR" "$term_dir" "$syskit_dir"; do
        if [[ ! -d "$dir" ]] || [[ -L "$dir" ]]; then
            break
        fi

        rmdir -- "$dir" 2>/dev/null || break
    done
}
