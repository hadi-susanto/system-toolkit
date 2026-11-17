#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__print_mise_status() {
    local version=""

    if ! mise_installed; then
        printf '%s[not-installed]%s\n' "$COLOR_CYAN" "$COLOR_RESET"

        return 0
    fi

    version="$(mise --version 2>/dev/null)" || version=""
    printf '%s[installed]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "${version%% *}"
}

__print_set_gobin_status() {
    local value

    if ! value="$(read_mise_go_set_gobin)"; then
        printf '%s[unavailable]%s mise not installed\n' "$COLOR_YELLOW" "$COLOR_RESET"

        return 0
    fi

    case "$value" in
        true)
            printf '%s[true]%s mise always overrides GOBIN' "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
        false)
            printf '%s[false]%s mise never sets GOBIN' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        *)
            printf '%s[default]%s mise sets GOBIN only when unset' "$COLOR_CYAN" "$COLOR_RESET"
            ;;
    esac

    if [[ -n "${MISE_GO_SET_GOBIN:-}" ]]; then
        printf ' (env override MISE_GO_SET_GOBIN=%s)' "$MISE_GO_SET_GOBIN"
    fi

    printf '\n'
}

__print_gobin_status() {
    local gobin

    if [[ ! -e "$__GOLANG_GOBIN_FILE" ]] && [[ ! -L "$__GOLANG_GOBIN_FILE" ]]; then
        printf '%s[not-configured]%s\n' "$COLOR_CYAN" "$COLOR_RESET"

        return 0
    fi

    if ! gobin="$(read_golang_gobin_state)"; then
        printf '%s[invalid]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$__GOLANG_GOBIN_FILE"

        return 0
    fi

    printf '%s[configured]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$gobin"
}

__print_session_status() {
    local gobin=""

    gobin="$(read_golang_gobin_state 2>/dev/null)" || gobin=""

    if [[ -z "${GOBIN:-}" ]]; then
        printf '%s[unset]%s\n' "$COLOR_CYAN" "$COLOR_RESET"

        return 0
    fi

    if [[ -n "$gobin" ]] && [[ "$GOBIN" != "$gobin" ]]; then
        printf '%s[warning]%s %s (differs from override; re-login or check mise go.set_gobin)\n' \
            "$COLOR_YELLOW" "$COLOR_RESET" "$GOBIN"

        return 0
    fi

    printf '%s\n' "$GOBIN"
}

__print_profile_status() {
    local state=0

    golang_profile_state || state=$?

    if (( state == 1 )); then
        printf '%s[not-installed]%s\n' "$COLOR_CYAN" "$COLOR_RESET"

        return 0
    fi

    if (( state == 2 )); then
        printf '%s[unmanaged]%s not written by SysKit\n' "$COLOR_RED" "$COLOR_RESET"

        return 0
    fi

    printf '%s[installed]%s\n' "$COLOR_GREEN" "$COLOR_RESET"
}

main() {
    printf 'Mise:\n'
    printf '  Command      : '
    __print_mise_status
    printf '  go.set_gobin : '
    __print_set_gobin_status

    printf 'GOBIN:\n'
    printf '  Override     : '
    __print_gobin_status
    printf '  Session      : '
    __print_session_status

    printf 'System Profile:\n'
    printf '  %s: ' "$__GOLANG_PROFILE_FILE"
    __print_profile_status
}

main "$@"
