#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/kitty.sh"

__uninstall_loader() {
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

__uninstall_file_config() {
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

main() {
    local selected

    while true; do
        printf 'Current Kitty Status:\n---------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Kitty Uninstallation:\n---------------------' \
                "Uninstall Loader" \
                "Uninstall File Config"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __uninstall_loader || return $?
                ;;
            2)
                __uninstall_file_config || return $?
                ;;
            X)
                return 0
                ;;
        esac

        printf '\n' >/dev/tty
    done
}

main "$@"
