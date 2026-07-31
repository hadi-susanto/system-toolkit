#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    local state_file="$HOME/.local/state/syskit/dev/sdkman/install-dir"
    local install_dir
    local -a lines=()

    if [[ ! -f "$state_file" ]] ||
        [[ -L "$state_file" ]] ||
        [[ ! -r "$state_file" ]]; then
        log_error "SDKMAN! state is unavailable: $state_file"
        log_error "Run SDKMAN_DIR=/absolute/path syskit-cfg install dev/sdkman first"

        return 1
    fi

    if ! mapfile -t lines <"$state_file"; then
        log_error "Failed to read SDKMAN! state: $state_file"

        return 1
    fi

    if (( ${#lines[@]} != 1 )) ||
        [[ -z "${lines[0]}" ]] ||
        [[ "${lines[0]}" != /* ]] ||
        [[ "${lines[0]}" == *$'\r'* ]]; then
        log_error "SDKMAN! state is malformed: $state_file"

        return 1
    fi

    install_dir="${lines[0]}"

    if [[ ! -f "$install_dir/bin/sdkman-init.sh" ]] ||
        [[ ! -r "$install_dir/bin/sdkman-init.sh" ]]; then
        log_error "SDKMAN! initialization is missing or unreadable: $install_dir/bin/sdkman-init.sh"

        return 1
    fi
}

main "$@"
