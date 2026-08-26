#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/ghostty.sh"

__install_loader() {
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

__install_file_config() {
    local source
    local target
    local file

    if ! install -d -m 0755 -- "$__GHOSTTY_CONFIG_DIR"; then
        log_error "Failed to create Ghostty configuration directory: $__GHOSTTY_CONFIG_DIR"

        return 1
    fi

    for file in "${__GHOSTTY_PAYLOAD_FILES[@]}"; do
        source="$CONFIG_MODULE_PAYLOAD/$file"
        target="$__GHOSTTY_CONFIG_DIR/$file"

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
    done
}

main() {
    local selected

    while true; do
        printf 'Current Ghostty Status:\n-----------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Ghostty Configuration:\n----------------------' \
                "Install Loader" \
                "Install File Config"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __install_loader || return $?
                ;;
            2)
                __install_file_config || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
