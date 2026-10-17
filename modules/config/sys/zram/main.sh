#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__require_installed() {
    if ! zram_installed; then
        log_error "zram-tools is not installed (missing $__ZRAM_SERVICE); install the zram-tools package first"

        return 1
    fi
}

__ask_validated() {
    local question="$1"
    local default_value="$2"
    local validator="$3"
    local error_message="$4"
    local value

    if ! value="$(ask_text "$question" "$default_value")"; then
        log_warn "Failed to obtain user input; the configuration was not changed"

        return 1
    fi

    if ! "$validator" "$value"; then
        log_error "$error_message: $value"

        return 1
    fi

    printf '%s\n' "$value"
}

__configure() {
    local algo
    local size=""
    local percent=""
    local priority
    local current_percent
    local current_size
    local current_algo
    local current_priority
    local mode
    local summary
    local size_label

    __require_installed || return 1

    current_algo="$(zram_conf_get ALGO)"
    current_size="$(zram_conf_get SIZE)"
    current_percent="$(zram_conf_get PERCENT)"
    current_priority="$(zram_conf_get PRIORITY)"

    algo="$(__ask_validated "Compression algorithm (${__ZRAM_ALGOS[*]})?" \
        "${current_algo:-$__ZRAM_DEFAULT_ALGO}" zram_valid_algo \
        "Algorithm must be one of ${__ZRAM_ALGOS[*]}")" || return 1

    if ! mode="$(choose_option $'zram size mode:\n----------------' \
        "Fixed size in MiB" "Percentage of total RAM")"; then
        return 1
    fi

    case "$mode" in
        1)
            size="$(__ask_validated "zram size in MiB?" \
                "${current_size:-$__ZRAM_DEFAULT_SIZE}" zram_valid_size \
                "Size must be a positive number of MiB")" || return 1
            size_label="$size MiB"
            ;;
        2)
            percent="$(__ask_validated "zram size as percent of RAM (1-100)?" \
                "${current_percent:-50}" zram_valid_percent \
                "Percent must be between 1 and 100")" || return 1
            size_label="$percent% of RAM"
            ;;
        *)
            return 0
            ;;
    esac

    priority="$(__ask_validated "Swap priority (higher is used first)?" \
        "${current_priority:-$__ZRAM_DEFAULT_PRIORITY}" zram_valid_priority \
        "Priority must be between -1 and 32767")" || return 1

    summary="The following zram configuration will be written to $__ZRAM_CONF:"$'\n'
    summary+="  Algorithm: $algo"$'\n'
    summary+="  Size     : $size_label"$'\n'
    summary+="  Priority : $priority"$'\n\n'
    summary+="Write this configuration?"

    if ! confirm_action "$summary"; then
        log_info "The zram configuration was not changed"

        return 0
    fi

    write_zram_conf "$algo" "$size" "$percent" "$priority" || return 1

    if ! zram_active_state; then
        log_info "Configuration saved; it applies when zram is enabled"

        return 0
    fi

    if confirm_action "Restart $__ZRAM_SERVICE now to apply it? (zram swap is turned off and on again)"; then
        log_info "Administrator privileges are required to restart $__ZRAM_SERVICE"

        if ! sudo systemctl restart "$__ZRAM_SERVICE"; then
            log_error "Failed to restart $__ZRAM_SERVICE"

            return 1
        fi

        log_info "Restarted $__ZRAM_SERVICE"
    else
        log_info "Configuration saved; it applies on the next restart of $__ZRAM_SERVICE"
    fi
}

__configure_swappiness() {
    local swappiness
    local page_cluster
    local current_swappiness
    local current_page_cluster
    local summary

    current_swappiness="$(zram_sysctl_conf_get vm.swappiness)"
    current_page_cluster="$(zram_sysctl_conf_get vm.page-cluster)"

    if [[ -z "$current_swappiness" ]]; then
        current_swappiness="$(zram_sysctl_live vm.swappiness || printf '%s' "$__ZRAM_DEFAULT_SWAPPINESS")"
    fi

    if [[ -z "$current_page_cluster" ]]; then
        current_page_cluster="$(zram_sysctl_live vm.page-cluster || printf '%s' "$__ZRAM_DEFAULT_PAGE_CLUSTER")"
    fi

    swappiness="$(__ask_validated "vm.swappiness (0-200; 100+ favors swapping, suits zram)?" \
        "$current_swappiness" zram_valid_swappiness \
        "Swappiness must be between 0 and 200")" || return 1

    page_cluster="$(__ask_validated "vm.page-cluster (0-15; pages read ahead = 2^N, 0 suits zram)?" \
        "$current_page_cluster" zram_valid_page_cluster \
        "Page cluster must be between 0 and 15")" || return 1

    summary="The following values will be saved to $__ZRAM_SYSCTL_CONF and applied now:"$'\n'
    summary+="  vm.swappiness  : $swappiness"$'\n'
    summary+="  vm.page-cluster: $page_cluster"$'\n\n'
    summary+="Apply these values?"

    if ! confirm_action "$summary"; then
        log_info "The sysctl values were not changed"

        return 0
    fi

    write_zram_sysctl "$swappiness" "$page_cluster" || return 1

    log_info "Set vm.swappiness=$swappiness and vm.page-cluster=$page_cluster"
}

__enable() {
    log_info "Administrator privileges are required to enable and start $__ZRAM_SERVICE"

    if ! sudo systemctl enable --now "$__ZRAM_SERVICE"; then
        log_error "Failed to enable $__ZRAM_SERVICE"

        return 1
    fi

    log_info "Enabled zram"
}

__disable() {
    if ! confirm_action "Disable zram? Its swap contents are moved to other swap or memory, which may be slow or fail if memory is tight."; then
        log_info "zram was not disabled"

        return 0
    fi

    log_info "Administrator privileges are required to stop and disable $__ZRAM_SERVICE"

    if ! sudo systemctl disable --now "$__ZRAM_SERVICE"; then
        log_error "Failed to disable $__ZRAM_SERVICE"

        return 1
    fi

    log_info "Disabled zram"
}

__toggle() {
    __require_installed || return 1

    if zram_active_state; then
        __disable
    else
        __enable
    fi
}

main() {
    local selected

    while true; do
        show_status $'Current zram Status:\n---------------------' \
            bash "$CONFIG_MODULE_DIR/status.sh" || return $?

        if ! selected="$(
            choose_option $'zram Configuration:\n-------------------' \
                "Configure zram" \
                "Configure swappiness" \
                "Enable/Disable zram"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        # A failed action is already logged; keep the menu open.
        case "$selected" in
            1)
                __configure || true
                ;;
            2)
                __configure_swappiness || true
                ;;
            3)
                __toggle || true
                ;;
            X)
                return 0
                ;;
        esac

        pause_prompt
    done
}

main "$@"
