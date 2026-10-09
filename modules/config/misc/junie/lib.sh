if (( ${__SYSKIT_JUNIE_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_JUNIE_CONFIG_LIB_LOADED=1

readonly __JUNIE_CONFIG_DIR="$HOME/.junie"
readonly __JUNIE_CONFIG_FILE="$__JUNIE_CONFIG_DIR/config.json"

##
# read_junie_auto_update_state
#
# Reads the persisted Junie auto-update state.
#
# Output:
#   Prints the stored `auto-update` value as "true" or "false", or nothing
#   when the config file is absent or the key is not set.
#
# Returns:
#   1 when jq is unavailable, the config file is a symbolic link, or the
#   config file exists but is not valid JSON.
#
read_junie_auto_update_state() {
    local value

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to read Junie configuration safely"

        return 1
    fi

    if [[ -L "$__JUNIE_CONFIG_FILE" ]]; then
        log_error "Invalid Junie configuration file: $__JUNIE_CONFIG_FILE"

        return 1
    fi

    if [[ ! -f "$__JUNIE_CONFIG_FILE" ]]; then
        return 0
    fi

    if ! value="$(jq -r '.["auto-update"] | if . == null then "" else tostring end' \
        "$__JUNIE_CONFIG_FILE" 2>/dev/null)"; then
        log_error "Invalid Junie configuration file: $__JUNIE_CONFIG_FILE"

        return 1
    fi

    if [[ -n "$value" ]]; then
        printf '%s\n' "$value"
    fi
}

##
# write_junie_auto_update_state <state>
#
# Sets `auto-update` to `true` or `false` in ~/.junie/config.json without
# disturbing any other key.
#
# The new content is assembled with jq into a swap file created alongside the
# config file, then renamed into place with `mv`. The existing config file is
# only ever replaced by a complete, valid swap file, so a failure here never
# leaves a truncated or partially written config file behind.
#
# Parameters:
#   state    Either "true" or "false".
#
# Returns:
#   1 when the state is invalid, jq is unavailable, the config path is
#   invalid, the config file is present but not valid JSON, or the swap file
#   cannot be written or installed.
#
write_junie_auto_update_state() {
    local state="$1"
    local swap_file
    local mode="0644"

    if [[ "$state" != "true" ]] && [[ "$state" != "false" ]]; then
        log_error "Invalid Junie auto-update state: $state"

        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to edit Junie configuration safely"

        return 1
    fi

    if [[ -L "$__JUNIE_CONFIG_DIR" ]] ||
        { [[ -e "$__JUNIE_CONFIG_DIR" ]] && [[ ! -d "$__JUNIE_CONFIG_DIR" ]]; }; then
        log_error "Invalid Junie configuration directory: $__JUNIE_CONFIG_DIR"

        return 1
    fi

    if [[ -L "$__JUNIE_CONFIG_FILE" ]]; then
        log_error "Invalid Junie configuration file: $__JUNIE_CONFIG_FILE"

        return 1
    fi

    if [[ -e "$__JUNIE_CONFIG_FILE" ]] && [[ ! -f "$__JUNIE_CONFIG_FILE" ]]; then
        log_error "Junie configuration path is not a regular file: $__JUNIE_CONFIG_FILE"

        return 1
    fi

    if ! mkdir -p -- "$__JUNIE_CONFIG_DIR"; then
        log_error "Failed to create Junie configuration directory: $__JUNIE_CONFIG_DIR"

        return 1
    fi

    if [[ -f "$__JUNIE_CONFIG_FILE" ]]; then
        mode="$(stat -c '%a' -- "$__JUNIE_CONFIG_FILE" 2>/dev/null)" || mode="0644"
    fi

    if ! swap_file="$(mktemp "$__JUNIE_CONFIG_FILE.XXXXXX")"; then
        log_error "Failed to create temporary Junie configuration swap file"

        return 1
    fi

    if [[ -f "$__JUNIE_CONFIG_FILE" ]]; then
        if ! jq --argjson state "$state" '.["auto-update"] = $state' \
            "$__JUNIE_CONFIG_FILE" >"$swap_file" 2>/dev/null; then
            log_error "Invalid Junie configuration file: $__JUNIE_CONFIG_FILE"
            rm -f -- "$swap_file"

            return 1
        fi
    else
        if ! jq -n --argjson state "$state" '{"auto-update": $state}' >"$swap_file"; then
            log_error "Failed to generate Junie configuration"
            rm -f -- "$swap_file"

            return 1
        fi
    fi

    if ! chmod "$mode" -- "$swap_file"; then
        log_error "Failed to secure temporary Junie configuration swap file: $swap_file"
        rm -f -- "$swap_file"

        return 1
    fi

    if ! mv -f -- "$swap_file" "$__JUNIE_CONFIG_FILE"; then
        log_error "Failed to install Junie configuration file: $__JUNIE_CONFIG_FILE"
        rm -f -- "$swap_file"

        return 1
    fi
}
