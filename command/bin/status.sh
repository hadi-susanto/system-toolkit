#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/checksum.sh"
source "$BIN_LIB/executables.sh"
source "$BIN_LIB/scope.sh"

__install_dir_status() {
    local install_dir="$1"

    if install_dir_in_path "$install_dir"; then
        printf '%s✓%s\n' "$COLOR_GREEN" "$COLOR_RESET"
    else
        printf '%s✗%s\n' "$COLOR_RED" "$COLOR_RESET"
    fi
}

main() {
    local -a executables
    local local_dir
    local global_dir
    local name
    local source
    local local_marker
    local global_marker
    local index=1
    local failed=0

    if [[ $# -gt 0 ]]; then
        log_error "The status command does not accept arguments"

        return 1
    fi

    list_bin_executables executables
    local_dir="$(local_install_dir)" || return $?
    global_dir="$(global_install_dir)"

    printf '%3s | %-30s | %-3s | %-3s\n' \
        'No' 'Executable' ' L' ' G'
    printf '%s\n' \
        '----+--------------------------------+-----+-----'

    for name in "${executables[@]}"; do
        source="${BIN_PAYLOAD}/${name}"
        if ! local_marker="$(bin_status_marker "$source" "$local_dir/$name")"; then
            failed=1
        fi

        if ! global_marker="$(bin_status_marker "$source" "$global_dir/$name")"; then
            failed=1
        fi

        printf '%3d | %-30s | %-6s | %-6s\n' \
            "$index" "$name" "$local_marker" "$global_marker"

        ((index += 1))
    done

    printf '\nLegends:\n'
    printf '  %s[✓]%s: Installed, checksum matched\n' "$COLOR_GREEN" "$COLOR_RESET"
    printf '  %s[✗]%s: Not Installed\n' "$COLOR_RED" "$COLOR_RESET"
    printf '  %s[↑]%s: Installed, update available (checksum mismatch)\n' "$COLOR_YELLOW" "$COLOR_RESET"
    printf '  %s[?]%s: Installed, checksum unavailable\n' "$COLOR_YELLOW" "$COLOR_RESET"
    printf '\nInstall Dir Statuses:\n'
    printf '  [$PATH: %s] (L)ocal : %s\n' "$(__install_dir_status "$local_dir")" "$local_dir"
    printf '  [$PATH: %s] (G)lobal: %s\n' "$(__install_dir_status "$global_dir")" "$global_dir"

    return "$failed"
}

main "$@"
