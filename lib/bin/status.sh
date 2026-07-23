#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$BIN_LIB/__executables.sh"
source "$BIN_LIB/__scope.sh"

__table_rule() {
    local width="$1"
    local rule

    printf -v rule '%*s' "$width" ''
    printf '%s' "${rule// /-}"
}

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

    if [[ $# -gt 0 ]]; then
        log_error "The status command does not accept arguments"
        bash "$BIN_LIB/help.sh" status >&2

        return 1
    fi

    if ! command -v sha256sum >/dev/null 2>&1; then
        log_error "Required command is unavailable: sha256sum"

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
        source="$SYSKIT_ROOT/bin/$name"
        local_marker="$(bin_status_marker "$source" "$local_dir/$name")"
        global_marker="$(bin_status_marker "$source" "$global_dir/$name")"

        printf '%3d | %-30s | %-6s | %-6s\n' \
            "$index" \
            "$name" \
            "$local_marker" \
            "$global_marker"

        ((index += 1))
    done
    
    printf '\nLegends:\n'
    printf '  %s[✓]%s: Installed, checksum matched\n' "$COLOR_GREEN" "$COLOR_RESET"
    printf '  %s[✗]%s: Not Installed\n' "$COLOR_RED" "$COLOR_RESET"
    printf '  %s[↑]%s: Installed, update available (checksum mismatch)\n' "$COLOR_YELLOW" "$COLOR_RESET"
    printf '\nInstall Dir Statuses:\n'
    printf '  [$PATH: %s] (L)ocal : %s\n' "$(__install_dir_status "$local_dir")" "$local_dir"
    printf '  [$PATH: %s] (G)lobal: %s\n' "$(__install_dir_status "$global_dir")" "$global_dir"
}

main "$@"
