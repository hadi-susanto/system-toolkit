#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__print_border() {
    local unit_width="$1"
    local enabled_width="$2"
    local active_width="$3"

    printf '+%s+%s+%s+\n' \
        "$(printf '%*s' "$((unit_width + 2))" '' | tr ' ' '-')" \
        "$(printf '%*s' "$((enabled_width + 2))" '' | tr ' ' '-')" \
        "$(printf '%*s' "$((active_width + 2))" '' | tr ' ' '-')"
}

__enabled_icon() {
    local state="$1"

    case "$state" in
        enabled)
            printf '%s\t%s\n' "✓" "$COLOR_GREEN"
            ;;
        disabled)
            printf '%s\t%s\n' "✗" "$COLOR_RED"
            ;;
        *)
            printf '%s\t%s\n' "?" "$COLOR_YELLOW"
            ;;
    esac
}

__active_icon() {
    local state="$1"

    case "$state" in
        active)
            printf '%s\t%s\n' "✓" "$COLOR_GREEN"
            ;;
        inactive)
            printf '%s\t%s\n' "✗" "$COLOR_RED"
            ;;
        failed)
            printf '%s\t%s\n' "!" "$COLOR_RED"
            ;;
        *)
            printf '%s\t%s\n' "?" "$COLOR_YELLOW"
            ;;
    esac
}

main() {
    local unit
    local symbol
    local color
    local unit_width=7
    local enabled_width=7
    local active_width=6
    local -a units=()
    local -a enabled_symbols=()
    local -a enabled_colors=()
    local -a active_symbols=()
    local -a active_colors=()

    if ! command -v systemctl >/dev/null 2>&1; then
        printf '%s[unknown]%s systemctl is not available\n' "$COLOR_RED" "$COLOR_RESET"

        return 1
    fi

    mapfile -t units < <(rclone_list_units)

    if (( ${#units[@]} == 0 )); then
        printf '%s[not-configured]%s No %s*.service units in %s\n' \
            "$COLOR_CYAN" "$COLOR_RESET" "$__RCLONE_UNIT_PREFIX" "$__RCLONE_UNIT_DIR"

        return 0
    fi

    for unit in "${units[@]}"; do
        IFS=$'\t' read -r symbol color < <(
            __enabled_icon "$(rclone_unit_enabled_state "$unit")"
        )
        enabled_symbols+=("$symbol")
        enabled_colors+=("$color")

        IFS=$'\t' read -r symbol color < <(
            __active_icon "$(rclone_unit_active_state "$unit")"
        )
        active_symbols+=("$symbol")
        active_colors+=("$color")

        if (( ${#unit} > unit_width )); then
            unit_width=${#unit}
        fi
    done

    __print_border "$unit_width" "$enabled_width" "$active_width"
    printf '| %-*s | %-*s | %-*s |\n' \
        "$unit_width" "Service" "$enabled_width" "Enabled" "$active_width" "Active"
    __print_border "$unit_width" "$enabled_width" "$active_width"

    # Icons are multibyte, so center the three-column "[x]" cell manually.
    local enabled_left=$(( (enabled_width - 3) / 2 ))
    local enabled_right=$(( enabled_width - 3 - enabled_left ))
    local active_left=$(( (active_width - 3) / 2 ))
    local active_right=$(( active_width - 3 - active_left ))
    local i
    for i in "${!units[@]}"; do
        printf '| %-*s | %*s%s[%s]%s%*s | %*s%s[%s]%s%*s |\n' \
            "$unit_width" "${units[i]}" \
            "$enabled_left" '' \
            "${enabled_colors[i]}" "${enabled_symbols[i]}" "$COLOR_RESET" \
            "$enabled_right" '' \
            "$active_left" '' \
            "${active_colors[i]}" "${active_symbols[i]}" "$COLOR_RESET" \
            "$active_right" ''
    done

    __print_border "$unit_width" "$enabled_width" "$active_width"
}

main "$@"
