#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib/ghostty.sh"

__uninstall_loader() {
    local loader_status=0
    local config_file="$__GHOSTTY_CONFIG_FILE"
    local config_tmp

    if ghostty_loader_state; then
        loader_status=0
    else
        loader_status=$?
    fi

    if (( loader_status == 1 )); then
        log_warn "Ghostty loader is not installed"

        return 0
    fi

    if (( loader_status == 2 )); then
        log_error "Ghostty loader markers are inconsistent: $__GHOSTTY_CONFIG_FILE"

        return 1
    fi

    if [[ -L "$config_file" ]]; then
        if ! config_file="$(readlink -f -- "$config_file")"; then
            log_error "Failed to resolve Ghostty configuration symlink: $__GHOSTTY_CONFIG_FILE"

            return 1
        fi
    fi

    if ! config_tmp="$(mktemp "$config_file.XXXXXX")"; then
        log_error "Failed to create a temporary Ghostty configuration file"

        return 1
    fi

    if ! awk \
        -v start="$__GHOSTTY_LOADER_START" \
        -v end="$__GHOSTTY_LOADER_END" '
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
        log_error "Failed to remove the Ghostty loader block"
        rm -f -- "$config_tmp"

        return 1
    fi

    if ! chmod --reference="$config_file" "$config_tmp"; then
        log_error "Failed to preserve Ghostty configuration permissions"
        rm -f -- "$config_tmp"

        return 1
    fi

    if ! mv -f -- "$config_tmp" "$config_file"; then
        log_error "Failed to update Ghostty configuration: $config_file"
        rm -f -- "$config_tmp"

        return 1
    fi

    log_info "Uninstalled Ghostty loader: $__GHOSTTY_CONFIG_FILE"
}

__uninstall_file_config() {
    local target
    local file
    local failed=0

    for file in "${__GHOSTTY_PAYLOAD_FILES[@]}"; do
        target="$__GHOSTTY_CONFIG_DIR/$file"

        if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
            log_warn "Ghostty configuration file is not installed: $target"
            continue
        fi

        if ! rm -f -- "$target"; then
            log_error "Failed to uninstall Ghostty configuration file: $target"
            failed=1
            continue
        fi

        log_info "Uninstalled Ghostty configuration file: $target"
    done

    return "$failed"
}

main() {
    local selected

    while true; do
        printf 'Current Ghostty Status:\n-----------------------\n'
        bash "$CONFIG_MODULE_DIR/status.sh" || return $?
        printf '\n' >/dev/tty

        if ! selected="$(
            choose_option \
                $'Ghostty Uninstallation:\n-----------------------' \
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
