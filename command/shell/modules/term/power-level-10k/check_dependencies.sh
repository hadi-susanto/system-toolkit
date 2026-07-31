#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    local state_file="$HOME/.local/state/syskit/term/power-level-10k/install-dir"
    local install_dir
    local -a lines=()

    if [[ ! -f "$state_file" ]] ||
        [[ -L "$state_file" ]] ||
        [[ ! -r "$state_file" ]]; then
        log_error "Powerlevel10k state is unavailable: $state_file"
        log_error "Run POWERLEVEL10K_INSTALL_DIR=/absolute/path syskit-cfg install term/power-level-10k first"

        return 1
    fi

    if ! mapfile -t lines <"$state_file"; then
        log_error "Failed to read Powerlevel10k state: $state_file"

        return 1
    fi

    if (( ${#lines[@]} != 1 )) ||
        [[ -z "${lines[0]}" ]] ||
        [[ "${lines[0]}" != /* ]] ||
        [[ "${lines[0]}" == *$'\r'* ]]; then
        log_error "Powerlevel10k state is malformed: $state_file"

        return 1
    fi

    install_dir="${lines[0]}"

    if [[ ! -f "$install_dir/powerlevel10k.zsh-theme" ]] ||
        [[ ! -r "$install_dir/powerlevel10k.zsh-theme" ]]; then
        log_error "Powerlevel10k theme is missing or unreadable: $install_dir/powerlevel10k.zsh-theme"

        return 1
    fi
}

main "$@"
