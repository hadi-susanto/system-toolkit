#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

main() {
    local channel
    local path
    local state
    local label
    local color
    local width=0
    local -a channels=()
    local -a paths=()
    local -a labels=()
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
                label="[✓] enabled"
                color="$COLOR_GREEN"
                ;;
            1)
                label="[✗] disabled"
                color="$COLOR_RED"
                ;;
            2)
                label="[-] not installed"
                color="$COLOR_YELLOW"
                ;;
            *)
                label="[?] unexpected file"
                color="$COLOR_YELLOW"
                ;;
        esac

        channels+=("$channel")
        paths+=("$path")
        labels+=("$label")
        colors+=("$color")

        if (( ${#path} > width )); then
            width=${#path}
        fi
    done

    printf '%-8s  %-*s  %s\n' "Channel" "$width" "Cron Job" "Status"
    printf '%-8s  %-*s  %s\n' "--------" "$width" "$(printf '%*s' "$width" '' | tr ' ' '-')" "------"

    local i
    for i in "${!channels[@]}"; do
        printf '%-8s  %-*s  %s%s%s\n' \
            "${channels[i]}" "$width" "${paths[i]}" \
            "${colors[i]}" "${labels[i]}" "$COLOR_RESET"
    done
}

main "$@"
