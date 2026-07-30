#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/kitty.sh"

__install_loader() {
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

__install_file_config() {
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

main() {
    local selected

    while true; do
        printf 'Current Kitty Status:\n---------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Kitty Configuration:\n--------------------' \
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
