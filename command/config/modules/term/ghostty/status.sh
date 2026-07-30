#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib/ghostty.sh"

__print_loader_status() {
    local loader_status=0

    if ghostty_loader_state; then
        printf '%s[✓]%s installed\n' "${COLOR_GREEN}" "${COLOR_RESET}"

        return 0
    else
        loader_status=$?
    fi

    if (( loader_status == 1 )); then
        printf '%s[✗]%s not installed\n' "${COLOR_RED}" "${COLOR_RESET}"

        return 0
    fi

    log_error "Ghostty loader markers are inconsistent: $__GHOSTTY_CONFIG_FILE"
    printf '%s[?]%s unknown\n' "${COLOR_YELLOW}" "${COLOR_RESET}"

    return 1
}

__print_file_config_status() {
    local file="$1"
    local source="$CONFIG_MODULE_PAYLOAD/$file"
    local target="$__GHOSTTY_CONFIG_DIR/$file"
    local source_checksum
    local target_checksum

    if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
        log_error "Ghostty configuration payload is unavailable: $source"

        return 1
    fi

    if [[ ! -f "$target" ]]; then
        printf '%s[✗]%s not installed\n' "${COLOR_RED}" "${COLOR_RESET}"

        return 0
    fi

    if ! command -v sha256sum >/dev/null 2>&1; then
        log_error "Required command is unavailable: sha256sum"

        return 1
    fi

    if ! source_checksum="$(sha256sum -- "$source" 2>/dev/null)"; then
        log_error "Failed to checksum Ghostty configuration payload: $source"

        return 1
    fi

    if ! target_checksum="$(sha256sum -- "$target" 2>/dev/null)"; then
        log_error "Failed to checksum installed Ghostty configuration: $target"

        return 1
    fi

    source_checksum="${source_checksum%% *}"
    target_checksum="${target_checksum%% *}"

    if [[ "$source_checksum" != "$target_checksum" ]]; then
        printf '%s[↑]%s update available\n' "${COLOR_YELLOW}" "${COLOR_RESET}"

        return 0
    fi

    printf '%s[✓]%s installed\n' "${COLOR_GREEN}" "${COLOR_RESET}"
}

main() {
    local failed=0

    printf 'Ghostty Loader: '
    if ! __print_loader_status; then
        failed=1
    fi

    printf 'Ghostty Configuration(s):\n'
    printf '  • syskit.ghostty: '
    if ! __print_file_config_status "syskit.ghostty"; then
        printf '%s[?]%s unknown\n' "${COLOR_YELLOW}" "${COLOR_RESET}"
        failed=1
    fi

    return "$failed"
}

main "$@"
