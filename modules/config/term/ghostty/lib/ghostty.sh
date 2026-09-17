if (( ${__SYSKIT_GHOSTTY_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_GHOSTTY_LIB_LOADED=1

readonly __GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
readonly __GHOSTTY_CONFIG_FILE="$__GHOSTTY_CONFIG_DIR/config.ghostty"
readonly __GHOSTTY_LOADER_START="# >>> syskit ghostty loader >>>"
readonly __GHOSTTY_LOADER_INCLUDE="config-file = ?syskit.ghostty"
readonly __GHOSTTY_LOADER_END="# <<< syskit ghostty loader <<<"
readonly __GHOSTTY_PAYLOAD_FILE="syskit.ghostty"

##
# ghostty_loader_state
#
# Checks whether config.ghostty contains one valid SysKit Ghostty loader block.
#
# Returns:
#   1 when config.ghostty or the managed loader block is absent.
#   2 when loader markers or managed block content are inconsistent.
#
ghostty_loader_state() {
    local has_start=0
    local has_end=0

    if [[ ! -f "$__GHOSTTY_CONFIG_FILE" ]]; then
        return 1
    fi

    if grep -Fqx -- "$__GHOSTTY_LOADER_START" "$__GHOSTTY_CONFIG_FILE"; then
        has_start=1
    fi

    if grep -Fqx -- "$__GHOSTTY_LOADER_END" "$__GHOSTTY_CONFIG_FILE"; then
        has_end=1
    fi

    if (( ! has_start && ! has_end )); then
        return 1
    fi

    if (( has_start != has_end )); then
        return 2
    fi

    if awk \
        -v start="$__GHOSTTY_LOADER_START" \
        -v include_line="$__GHOSTTY_LOADER_INCLUDE" \
        -v end="$__GHOSTTY_LOADER_END" '
            $0 == start {
                if (inside || found) {
                    invalid = 1
                }

                inside = 1
                next
            }

            inside && $0 == include_line {
                if (has_include) {
                    invalid = 1
                }

                has_include = 1
                next
            }

            $0 == end {
                if (!inside || !has_include) {
                    invalid = 1
                }

                inside = 0
                found = 1
                next
            }

            inside {
                invalid = 1
            }

            END {
                valid = found && !inside && !invalid

                if (valid) {
                    exit 0
                }

                exit 1
            }
        ' "$__GHOSTTY_CONFIG_FILE"; then
        return 0
    fi

    return 2
}

install_ghostty_loader() {
    local loader_status=0
    local last_byte

    if ghostty_loader_state; then
        log_warn "Ghostty loader is already installed"

        return 0
    else
        loader_status=$?
    fi

    if (( loader_status == 2 )); then
        log_error "Ghostty loader markers are inconsistent: $__GHOSTTY_CONFIG_FILE"

        return 1
    fi

    if ! install -d -m 0755 -- "$__GHOSTTY_CONFIG_DIR"; then
        log_error "Failed to create Ghostty configuration directory: $__GHOSTTY_CONFIG_DIR"

        return 1
    fi

    if [[ ! -e "$__GHOSTTY_CONFIG_FILE" ]] &&
        ! install -m 0644 -- /dev/null "$__GHOSTTY_CONFIG_FILE"; then
        log_error "Failed to create Ghostty configuration file: $__GHOSTTY_CONFIG_FILE"

        return 1
    fi

    if [[ ! -f "$__GHOSTTY_CONFIG_FILE" ]]; then
        log_error "Ghostty configuration path is not a regular file: $__GHOSTTY_CONFIG_FILE"

        return 1
    fi

    if [[ -s "$__GHOSTTY_CONFIG_FILE" ]]; then
        if ! last_byte="$(tail -c 1 -- "$__GHOSTTY_CONFIG_FILE")"; then
            log_error "Failed to inspect Ghostty configuration: $__GHOSTTY_CONFIG_FILE"

            return 1
        fi

        if [[ -n "$last_byte" ]] &&
            ! printf '\n' >>"$__GHOSTTY_CONFIG_FILE"; then
            log_error "Failed to terminate Ghostty configuration content"

            return 1
        fi

        if ! printf '\n' >>"$__GHOSTTY_CONFIG_FILE"; then
            log_error "Failed to separate the Ghostty loader configuration"

            return 1
        fi
    fi

    if ! printf '%s\n' \
        "$__GHOSTTY_LOADER_START" \
        "$__GHOSTTY_LOADER_INCLUDE" \
        "$__GHOSTTY_LOADER_END" >>"$__GHOSTTY_CONFIG_FILE"; then
        log_error "Failed to install the Ghostty loader"

        return 1
    fi

    log_info "Installed Ghostty loader: $__GHOSTTY_CONFIG_FILE"
}

install_ghostty_file_config() {
    local source
    local target
    local file

    if ! install -d -m 0755 -- "$__GHOSTTY_CONFIG_DIR"; then
        log_error "Failed to create Ghostty configuration directory: $__GHOSTTY_CONFIG_DIR"

        return 1
    fi

    source="$CONFIG_MODULE_PAYLOAD/$__GHOSTTY_PAYLOAD_FILE"
    target="$__GHOSTTY_CONFIG_DIR/$__GHOSTTY_PAYLOAD_FILE"

    if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
        log_error "Ghostty configuration payload is unavailable: $source"

        return 1
    fi

    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        if [[ "${CONFIG_FORCE:-false}" != "true" ]]; then
            log_warn "Ghostty configuration file already exists; skipping: $target"
            log_info "Re-run the configuration with --force to overwrite it"

            continue
        fi

        log_warn "Overwriting Ghostty configuration file: $target"
    fi

    if ! install -m 0644 -- "$source" "$target"; then
        log_error "Failed to install Ghostty configuration file: $target"

        return 1
    fi

    log_info "Installed Ghostty configuration file: $target"
}

uninstall_ghostty_loader() {
    local loader_status=0
    local config_file="$__GHOSTTY_CONFIG_FILE"
    local config_tmp

    if ghostty_loader_state; then
        loader_status=0
    else
        loader_status=$?
    fi

    if (( loader_status == 1 )); then
        log_warn "Ghostty loader is not installed"

        return 0
    fi

    if (( loader_status == 2 )); then
        log_error "Ghostty loader markers are inconsistent: $__GHOSTTY_CONFIG_FILE"

        return 1
    fi

    if [[ -L "$config_file" ]]; then
        if ! config_file="$(readlink -f -- "$config_file")"; then
            log_error "Failed to resolve Ghostty configuration symlink: $__GHOSTTY_CONFIG_FILE"

            return 1
        fi
    fi

    if ! config_tmp="$(mktemp "$config_file.XXXXXX")"; then
        log_error "Failed to create a temporary Ghostty configuration file"

        return 1
    fi

    if ! awk \
        -v start="$__GHOSTTY_LOADER_START" \
        -v end="$__GHOSTTY_LOADER_END" '
            inside {
                if ($0 == end) {
                    inside = 0
                }

                next
            }

            $0 == start {
                inside = 1

                if (buffered && previous != "") {
                    print previous
                }

                buffered = 0
                next
            }

            buffered {
                print previous
            }

            {
                previous = $0
                buffered = 1
            }

            END {
                if (buffered) {
                    print previous
                }
            }
        ' "$config_file" >"$config_tmp"; then
        log_error "Failed to remove the Ghostty loader block"
        rm -f -- "$config_tmp"

        return 1
    fi

    if ! chmod --reference="$config_file" "$config_tmp"; then
        log_error "Failed to preserve Ghostty configuration permissions"
        rm -f -- "$config_tmp"

        return 1
    fi

    if ! mv -f -- "$config_tmp" "$config_file"; then
        log_error "Failed to update Ghostty configuration: $config_file"
        rm -f -- "$config_tmp"

        return 1
    fi

    log_info "Uninstalled Ghostty loader: $__GHOSTTY_CONFIG_FILE"
}

uninstall_ghostty_file_config() {
    local target
    local file
    local failed=0

    target="$__GHOSTTY_CONFIG_DIR/$__GHOSTTY_PAYLOAD_FILE"

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        log_warn "Ghostty configuration file is not installed: $target"
        continue
    fi

    if ! rm -f -- "$target"; then
        log_error "Failed to uninstall Ghostty configuration file: $target"
        failed=1
        continue
    fi

    log_info "Uninstalled Ghostty configuration file: $target"

    return "$failed"
}
