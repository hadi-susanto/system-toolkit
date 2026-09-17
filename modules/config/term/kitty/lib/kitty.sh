if (( ${__SYSKIT_KITTY_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_KITTY_LIB_LOADED=1

readonly __KITTY_CONFIG_DIR="$HOME/.config/kitty"
readonly __KITTY_CONFIG_FILE="$__KITTY_CONFIG_DIR/kitty.conf"
readonly __KITTY_LOADER_START="# >>> syskit kitty loader >>>"
readonly __KITTY_LOADER_INCLUDE="globinclude syskit.kitty"
readonly __KITTY_LOADER_END="# <<< syskit kitty loader <<<"
readonly -a __KITTY_PAYLOAD_FILES=(
    "syskit.kitty"
    "syskit.session"
)

##
# kitty_loader_state
#
# Checks whether kitty.conf contains one valid SysKit Kitty loader block.
#
# Returns:
#   1 when kitty.conf or the managed loader block is absent.
#   2 when loader markers or managed block content are inconsistent.
#
kitty_loader_state() {
    local has_start=0
    local has_end=0

    if [[ ! -f "$__KITTY_CONFIG_FILE" ]]; then
        return 1
    fi

    if grep -Fqx -- "$__KITTY_LOADER_START" "$__KITTY_CONFIG_FILE"; then
        has_start=1
    fi

    if grep -Fqx -- "$__KITTY_LOADER_END" "$__KITTY_CONFIG_FILE"; then
        has_end=1
    fi

    if (( ! has_start && ! has_end )); then
        return 1
    fi

    if (( has_start != has_end )); then
        return 2
    fi

    if awk \
        -v start="$__KITTY_LOADER_START" \
        -v include_line="$__KITTY_LOADER_INCLUDE" \
        -v end="$__KITTY_LOADER_END" '
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
        ' "$__KITTY_CONFIG_FILE"; then
        return 0
    fi

    return 2
}

install_kitty_loader() {
    local loader_status=0
    local last_byte

    if kitty_loader_state; then
        log_warn "Kitty loader is already installed"

        return 0
    else
        loader_status=$?
    fi

    if (( loader_status == 2 )); then
        log_error "Kitty loader markers are inconsistent: $__KITTY_CONFIG_FILE"

        return 1
    fi

    if ! install -d -m 0755 -- "$__KITTY_CONFIG_DIR"; then
        log_error "Failed to create Kitty configuration directory: $__KITTY_CONFIG_DIR"

        return 1
    fi

    if [[ ! -e "$__KITTY_CONFIG_FILE" ]] &&
        ! install -m 0644 -- /dev/null "$__KITTY_CONFIG_FILE"; then
        log_error "Failed to create Kitty configuration file: $__KITTY_CONFIG_FILE"

        return 1
    fi

    if [[ ! -f "$__KITTY_CONFIG_FILE" ]]; then
        log_error "Kitty configuration path is not a regular file: $__KITTY_CONFIG_FILE"

        return 1
    fi

    if [[ -s "$__KITTY_CONFIG_FILE" ]]; then
        if ! last_byte="$(tail -c 1 -- "$__KITTY_CONFIG_FILE")"; then
            log_error "Failed to inspect Kitty configuration: $__KITTY_CONFIG_FILE"

            return 1
        fi

        if [[ -n "$last_byte" ]] &&
            ! printf '\n' >>"$__KITTY_CONFIG_FILE"; then
            log_error "Failed to terminate Kitty configuration content"

            return 1
        fi

        if ! printf '\n' >>"$__KITTY_CONFIG_FILE"; then
            log_error "Failed to separate the Kitty loader configuration"

            return 1
        fi
    fi

    if ! printf '%s\n' \
        "$__KITTY_LOADER_START" \
        "$__KITTY_LOADER_INCLUDE" \
        "$__KITTY_LOADER_END" >>"$__KITTY_CONFIG_FILE"; then
        log_error "Failed to install the Kitty loader"

        return 1
    fi

    log_info "Installed Kitty loader: $__KITTY_CONFIG_FILE"
}

install_kitty_files() {
    local source
    local target
    local file

    if ! install -d -m 0755 -- "$__KITTY_CONFIG_DIR"; then
        log_error "Failed to create Kitty configuration directory: $__KITTY_CONFIG_DIR"

        return 1
    fi

    for file in "${__KITTY_PAYLOAD_FILES[@]}"; do
        source="$CONFIG_MODULE_PAYLOAD/$file"
        target="$__KITTY_CONFIG_DIR/$file"

        if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
            log_error "Kitty configuration payload is unavailable: $source"

            return 1
        fi

        if [[ -e "$target" ]] || [[ -L "$target" ]]; then
            if [[ "${CONFIG_FORCE:-false}" != "true" ]]; then
                log_warn "Kitty configuration file already exists; skipping: $target"
                log_info "Re-run the configuration with --force to overwrite it"

                continue
            fi

            log_warn "Overwriting Kitty configuration file: $target"
        fi

        if ! install -m 0644 -- "$source" "$target"; then
            log_error "Failed to install Kitty configuration file: $target"

            return 1
        fi

        log_info "Installed Kitty configuration file: $target"
    done
}

uninstall_kitty_loader() {
    local loader_status=0
    local config_file="$__KITTY_CONFIG_FILE"
    local config_tmp

    if kitty_loader_state; then
        loader_status=0
    else
        loader_status=$?
    fi

    if (( loader_status == 1 )); then
        log_warn "Kitty loader is not installed"

        return 0
    fi

    if (( loader_status == 2 )); then
        log_error "Kitty loader markers are inconsistent: $__KITTY_CONFIG_FILE"

        return 1
    fi

    if [[ -L "$config_file" ]]; then
        if ! config_file="$(readlink -f -- "$config_file")"; then
            log_error "Failed to resolve Kitty configuration symlink: $__KITTY_CONFIG_FILE"

            return 1
        fi
    fi

    if ! config_tmp="$(mktemp "$config_file.XXXXXX")"; then
        log_error "Failed to create a temporary Kitty configuration file"

        return 1
    fi

    if ! awk \
        -v start="$__KITTY_LOADER_START" \
        -v end="$__KITTY_LOADER_END" '
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
        log_error "Failed to remove the Kitty loader block"
        rm -f -- "$config_tmp"

        return 1
    fi

    if ! chmod --reference="$config_file" "$config_tmp"; then
        log_error "Failed to preserve Kitty configuration permissions"
        rm -f -- "$config_tmp"

        return 1
    fi

    if ! mv -f -- "$config_tmp" "$config_file"; then
        log_error "Failed to update Kitty configuration: $config_file"
        rm -f -- "$config_tmp"

        return 1
    fi

    log_info "Uninstalled Kitty loader: $__KITTY_CONFIG_FILE"
}

uninstall_kitty_files() {
    local target
    local file
    local failed=0

    for file in "${__KITTY_PAYLOAD_FILES[@]}"; do
        target="$__KITTY_CONFIG_DIR/$file"

        if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
            log_warn "Kitty configuration file is not installed: $target"
            continue
        fi

        if ! rm -f -- "$target"; then
            log_error "Failed to uninstall Kitty configuration file: $target"
            failed=1
            continue
        fi

        log_info "Uninstalled Kitty configuration file: $target"
    done

    return "$failed"
}
