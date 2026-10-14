if (( ${__SYSKIT_PROMPT_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_PROMPT_LOADED=1

source "$COMMON_LIB/common.sh"

if [[ -r /dev/tty && -w /dev/tty ]] &&
    { : </dev/tty; } 2>/dev/null &&
    { : >/dev/tty; } 2>/dev/null; then
    :
else
    log_error "An interactive terminal is required to load the prompt library"

    return 1
fi

# Loader: selects the whiptail backend when usable, otherwise the pure-bash one.
# Both backends expose choose_option, confirm_action and ask_text with the same
# contract. Set DISABLE_WHIPTAIL=true to force the pure-bash backend.
if [[ "${DISABLE_WHIPTAIL:-false}" != "true" ]] &&
    command -v whiptail >/dev/null 2>&1 &&
    [[ -n "${TERM:-}" && "$TERM" != "dumb" ]]; then
    source "$COMMON_LIB/__prompt-whiptail.sh" || return $?
else
    source "$COMMON_LIB/__prompt-basic.sh" || return $?
fi
