#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__print_border() {
    local path_width="$1"
    local label_width="$2"

    printf '+%s+%s+%s+\n' \
        "$(printf '%*s' 10 '' | tr ' ' '-')" \
        "$(printf '%*s' "$((path_width + 2))" '' | tr ' ' '-')" \
        "$(printf '%*s' "$((label_width + 2))" '' | tr ' ' '-')"
}

main() {
    local channel
    local path
    local state
    local symbol
    local text
    local color
    local path_width=8
    local label_width=6
    local -a channels=()
    local -a paths=()
    local -a symbols=()
    local -a texts=()
    local -a colors=()

    for channel in "${__EDGE_CHANNELS[@]}"; do
        path="$(edge_cron_path "$channel")"

        if edge_cron_state "$path"; then
            state=0
        else
            state=$?
        fi

        case "$state" in
            0)
                symbol="✓"; text="enabled"
                color="$COLOR_GREEN"
                ;;
            1)
                symbol="✗"; text="disabled"
                color="$COLOR_RED"
                ;;
            2)
                symbol="-"; text="not installed"
                color="$COLOR_YELLOW"
                ;;
            *)
                symbol="?"; text="unexpected file"
                color="$COLOR_YELLOW"
                ;;
        esac

        channels+=("$channel")
        paths+=("$path")
        symbols+=("$symbol")
        texts+=("$text")
        colors+=("$color")

        if (( ${#path} > path_width )); then
            path_width=${#path}
        fi

        if (( ${#text} + 4 > label_width )); then
            label_width=$(( ${#text} + 4 ))
        fi
    done

    __print_border "$path_width" "$label_width"
    printf '| %-8s | %-*s | %-*s |\n' \
        "Channel" "$path_width" "Cron Job" "$label_width" "Status"
    __print_border "$path_width" "$label_width"

    local i
    for i in "${!channels[@]}"; do
        printf '| %-8s | %-*s | %s[%s]%s %-*s |\n' \
            "${channels[i]}" "$path_width" "${paths[i]}" \
            "${colors[i]}" "${symbols[i]}" "$COLOR_RESET" \
            "$((label_width - 4))" "${texts[i]}"
    done

    __print_border "$path_width" "$label_width"
}

main "$@"
