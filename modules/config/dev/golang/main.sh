#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/path.sh"
source "$COMMON_LIB/prompt.sh"
source "$CONFIG_MODULE_DIR/lib.sh"

__install_gobin_state() {
    local current_gobin
    local new_gobin

    if ! current_gobin="$(read_golang_gobin_state)"; then
        current_gobin="$HOME/go/bin"
    fi

    if ! new_gobin="$(ask_text "Where should go install place binaries (GOBIN)?" "$current_gobin")"; then
        log_warn "Fail to obtain user concern, prevent write GOBIN state file"

        return 0
    fi

    new_gobin="$(expand_path "$new_gobin")" || return $?
    if ! can_write "$new_gobin"; then
        log_error "Unable $new_gobin is not writable with current user privilege, please use other path."

        return 1
    fi

    write_golang_gobin_state "$new_gobin" || return $?
    log_info "Stored GOBIN override: $new_gobin"

    if golang_profile_state; then
        log_info "Log out and back in to apply it"
    else
        log_info "Add $__GOLANG_PROFILE_FILE so login sessions export it"
    fi
}

__enable_mise_set_gobin() {
    if read_golang_gobin_state >/dev/null; then
        log_warn "Mise will override the SysKit GOBIN override in mise-activated shells"
    fi

    set_mise_go_set_gobin true
}

__install_profile() {
    local confirmation_status

    if confirm_action "Write $__GOLANG_PROFILE_FILE to export GOBIN for login shells?"; then
        :
    else
        confirmation_status=$?

        if (( confirmation_status == 1 )); then
            log_info "Go profile changes were cancelled"

            return 0
        fi

        return "$confirmation_status"
    fi

    write_golang_profile
}

main() {
    local selected
    local -a options=()
    local profile_installed=0
    local profile_current_status=0

    while true; do
        show_status $'Current Go Status:\n-----------------------' \
            bash "$CONFIG_MODULE_DIR/status.sh" || return $?

        options=(
            "Override Go binary dir (GOBIN)"
            "Remove GOBIN override"
            "Set mise go.set_gobin = true (mise always overrides GOBIN)"
            "Set mise go.set_gobin = false (mise never sets GOBIN)"
            "Reset mise go.set_gobin to default (mise sets GOBIN only when unset)"
        )
        if golang_profile_state; then
            profile_installed=1
            options+=("Remove GOBIN from $__GOLANG_PROFILE_FILE")
        else
            profile_installed=0
            options+=("Add GOBIN into $__GOLANG_PROFILE_FILE (login shells and GUI apps)")
        fi

        # Offer an update only when the installed profile differs from the payload
        profile_current_status=0
        if (( profile_installed )); then
            golang_profile_current 2>/dev/null || profile_current_status=$?
        fi
        if (( profile_current_status == 1 )); then
            options+=("Update $__GOLANG_PROFILE_FILE (update available)")
        fi

        if ! selected="$(
            choose_option $'Go Configuration:\n----------------------' "${options[@]}"
        )"; then
            return 1
        fi

        printf '\n' >/dev/tty

        case "$selected" in
            1)
                __install_gobin_state
                ;;
            2)
                remove_golang_gobin_state
                ;;
            3)
                __enable_mise_set_gobin || return $?
                ;;
            4)
                set_mise_go_set_gobin false || return $?
                ;;
            5)
                unset_mise_go_set_gobin || return $?
                ;;
            6)
                if (( profile_installed )); then
                    remove_golang_profile || return $?
                else
                    __install_profile || return $?
                fi
                ;;
            7)
                write_golang_profile || return $?
                ;;
            X)
                return 0
                ;;
        esac

        pause_prompt
    done
}

main "$@"
