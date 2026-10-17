#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

main() {
    local size
    local line
    local value
    local used
    local compressed

    if ! zram_installed; then
        printf 'zram             : %s[?]%s zram-tools (%s) is not installed\n' \
            "$COLOR_YELLOW" "$COLOR_RESET" "$__ZRAM_SERVICE"

        return 0
    fi

    if zram_active_state; then
        printf 'zram             : %s[✓]%s enabled\n' "$COLOR_GREEN" "$COLOR_RESET"

        if size="$(zram_device_size)"; then
            printf 'Size             : %s\n' "$size"
        fi

        if command -v zramctl >/dev/null 2>&1; then
            line="$(zramctl --noheadings --raw -o ALGORITHM,DATA,COMPR 2>/dev/null | head -n1 || true)"
            if [[ -n "$line" ]]; then
                read -r value used compressed <<<"$line"
                printf 'Algorithm        : %s\n' "$value"
                printf 'Used / Compressed: %s / %s\n' "$used" "$compressed"
            fi
        fi
    else
        printf 'zram             : %s[✗]%s disabled\n' "$COLOR_RED" "$COLOR_RESET"
    fi

    if zram_service_enabled_state; then
        printf 'Start at Boot    : %s[✓]%s yes\n' "$COLOR_GREEN" "$COLOR_RESET"
    else
        printf 'Start at Boot    : %s[✗]%s no\n' "$COLOR_RED" "$COLOR_RESET"
    fi

    value="$(zram_conf_get PERCENT)"

    if [[ -n "$value" ]]; then
        printf 'Configured Size  : %s%% of RAM\n' "$value"
    else
        printf 'Configured Size  : %s MiB\n' "$(zram_conf_get SIZE)"
    fi

    printf 'Configured Algo  : %s\n' "$(zram_conf_get ALGO)"
    printf 'Configured Prio  : %s\n' "$(zram_conf_get PRIORITY)"
}

main "$@"
