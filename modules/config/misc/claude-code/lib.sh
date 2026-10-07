if (( ${__SYSKIT_CLAUDE_CODE_CONFIG_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_CLAUDE_CODE_CONFIG_LIB_LOADED=1

readonly __CLAUDE_CODE_SETTINGS_DIR="$HOME/.claude"
readonly __CLAUDE_CODE_SETTINGS_FILE="$__CLAUDE_CODE_SETTINGS_DIR/settings.json"

##
# read_claude_code_auto_updater_status
#
# Reads the persisted Claude Code auto-updater status.
#
# Output:
#   Prints the stored `autoUpdaterStatus` value, or nothing when the settings
#   file is absent or the key is not set.
#
# Returns:
#   1 when jq is unavailable, the settings file is a symbolic link, or the
#   settings file exists but is not valid JSON.
#
read_claude_code_auto_updater_status() {
    local value

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to read Claude Code settings safely"

        return 1
    fi

    if [[ -L "$__CLAUDE_CODE_SETTINGS_FILE" ]]; then
        log_error "Invalid Claude Code settings file: $__CLAUDE_CODE_SETTINGS_FILE"

        return 1
    fi

    if [[ ! -f "$__CLAUDE_CODE_SETTINGS_FILE" ]]; then
        return 0
    fi

    if ! value="$(jq -r '.autoUpdaterStatus // empty' "$__CLAUDE_CODE_SETTINGS_FILE" 2>/dev/null)"; then
        log_error "Invalid Claude Code settings file: $__CLAUDE_CODE_SETTINGS_FILE"

        return 1
    fi

    if [[ -n "$value" ]]; then
        printf '%s\n' "$value"
    fi
}

##
# write_claude_code_auto_updater_status <status>
#
# Sets `autoUpdaterStatus` to "enabled" or "disabled" in
# ~/.claude/settings.json without disturbing any other key.
#
# The new content is assembled with jq into a swap file created alongside the
# settings file, then renamed into place with `mv`. The existing settings file
# is only ever replaced by a complete, valid swap file, so a failure here
# never leaves a truncated or partially written settings file behind.
#
# Parameters:
#   status    Either "enabled" or "disabled".
#
# Returns:
#   1 when the status is invalid, jq is unavailable, the settings path is
#   invalid, the settings file is present but not valid JSON, or the swap file
#   cannot be written or installed.
#
write_claude_code_auto_updater_status() {
    local status="$1"
    local swap_file
    local mode="0644"

    if [[ "$status" != "enabled" ]] && [[ "$status" != "disabled" ]]; then
        log_error "Invalid Claude Code auto-updater status: $status"

        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to edit Claude Code settings safely"

        return 1
    fi

    if [[ -L "$__CLAUDE_CODE_SETTINGS_DIR" ]] ||
        { [[ -e "$__CLAUDE_CODE_SETTINGS_DIR" ]] && [[ ! -d "$__CLAUDE_CODE_SETTINGS_DIR" ]]; }; then
        log_error "Invalid Claude Code settings directory: $__CLAUDE_CODE_SETTINGS_DIR"

        return 1
    fi

    if [[ -L "$__CLAUDE_CODE_SETTINGS_FILE" ]]; then
        log_error "Invalid Claude Code settings file: $__CLAUDE_CODE_SETTINGS_FILE"

        return 1
    fi

    if [[ -e "$__CLAUDE_CODE_SETTINGS_FILE" ]] && [[ ! -f "$__CLAUDE_CODE_SETTINGS_FILE" ]]; then
        log_error "Claude Code settings path is not a regular file: $__CLAUDE_CODE_SETTINGS_FILE"

        return 1
    fi

    if ! mkdir -p -- "$__CLAUDE_CODE_SETTINGS_DIR"; then
        log_error "Failed to create Claude Code settings directory: $__CLAUDE_CODE_SETTINGS_DIR"

        return 1
    fi

    if [[ -f "$__CLAUDE_CODE_SETTINGS_FILE" ]]; then
        mode="$(stat -c '%a' -- "$__CLAUDE_CODE_SETTINGS_FILE" 2>/dev/null)" || mode="0644"
    fi

    if ! swap_file="$(mktemp "$__CLAUDE_CODE_SETTINGS_FILE.XXXXXX")"; then
        log_error "Failed to create temporary Claude Code settings swap file"

        return 1
    fi

    if [[ -f "$__CLAUDE_CODE_SETTINGS_FILE" ]]; then
        if ! jq --arg status "$status" '.autoUpdaterStatus = $status' \
            "$__CLAUDE_CODE_SETTINGS_FILE" >"$swap_file" 2>/dev/null; then
            log_error "Invalid Claude Code settings file: $__CLAUDE_CODE_SETTINGS_FILE"
            rm -f -- "$swap_file"

            return 1
        fi
    else
        if ! jq -n --arg status "$status" '{"autoUpdaterStatus": $status}' >"$swap_file"; then
            log_error "Failed to generate Claude Code settings"
            rm -f -- "$swap_file"

            return 1
        fi
    fi

    if ! chmod "$mode" -- "$swap_file"; then
        log_error "Failed to secure temporary Claude Code settings swap file: $swap_file"
        rm -f -- "$swap_file"

        return 1
    fi

    if ! mv -f -- "$swap_file" "$__CLAUDE_CODE_SETTINGS_FILE"; then
        log_error "Failed to install Claude Code settings file: $__CLAUDE_CODE_SETTINGS_FILE"
        rm -f -- "$swap_file"

        return 1
    fi
}
