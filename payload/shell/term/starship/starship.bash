# Check required dependencies
if ! command -v starship >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m starship is not installed; skipping Starship\n' >&2

    return 0
fi

__syskit_starship_first_prompt=1

__syskit_starship_newline() {
    if (( __syskit_starship_first_prompt == 0 )); then
        printf '\n'
    else
        __syskit_starship_first_prompt=0
    fi
}

if [[ -n "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="__syskit_starship_newline;${PROMPT_COMMAND}"
else
    PROMPT_COMMAND="__syskit_starship_newline"
fi

eval "$(starship init bash)"
