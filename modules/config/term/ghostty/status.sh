#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/checksum.sh"
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
    local source="$CONFIG_MODULE_PAYLOAD/$__GHOSTTY_PAYLOAD_FILE"
    local target="$__GHOSTTY_CONFIG_DIR/$__GHOSTTY_PAYLOAD_FILE"
    local checksum_status=0

    if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
        log_error "Ghostty configuration payload is unavailable: $source"

        return 1
    fi

    if [[ ! -f "$target" ]]; then
        printf '%s[✗]%s not installed\n' "${COLOR_RED}" "${COLOR_RESET}"

        return 0
    fi

    if checksums_match "$source" "$target"; then
        checksum_status=0
    else
        checksum_status=$?
    fi

    case "$checksum_status" in
        0)
            printf '%s[✓]%s installed\n' "${COLOR_GREEN}" "${COLOR_RESET}"
            ;;
        1)
            printf '%s[↑]%s update available\n' "${COLOR_YELLOW}" "${COLOR_RESET}"
            ;;
        2)
            printf '%s[?]%s source checksum fail\n' "${COLOR_YELLOW}" "${COLOR_RESET}"
            log_error "Failed to checksum Ghostty configuration payload: $source"

            return 1
            ;;
        3)
            printf '%s[?]%s target checksum fail\n' "${COLOR_YELLOW}" "${COLOR_RESET}"
            log_error "Failed to checksum installed Ghostty configuration: $target"

            return 1
            ;;
        127)
            printf '%s[?]%s missing sha256sum binary\n' "${COLOR_YELLOW}" "${COLOR_RESET}"
            log_error "Required command is unavailable: sha256sum"

            return 1
            ;;
    esac
}

main() {
    local failed=0

    printf 'Ghostty Loader: '
    if ! __print_loader_status; then
        failed=1
    fi

    printf 'Ghostty Config: '
    if ! __print_file_config_status; then
        failed=1
    fi

    return "$failed"
}

main "$@"
