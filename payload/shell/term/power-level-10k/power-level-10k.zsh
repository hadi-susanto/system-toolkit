__syskit_powerlevel10k_state_file="$HOME/.local/state/syskit/term/power-level-10k/install-dir"

if [[ -L "$__syskit_powerlevel10k_state_file" ]] ||
    [[ ! -f "$__syskit_powerlevel10k_state_file" ]] ||
    [[ ! -r "$__syskit_powerlevel10k_state_file" ]]; then
    printf '\033[31m[ERROR]\033[0m Powerlevel10k state is unavailable; skipping Powerlevel10k integration: %s\n' \
        "$__syskit_powerlevel10k_state_file" >&2
    unset __syskit_powerlevel10k_state_file

    return 0
fi

if ! IFS= read -r __syskit_powerlevel10k_install_dir <"$__syskit_powerlevel10k_state_file" ||
    [[ -z "$__syskit_powerlevel10k_install_dir" ]] ||
    [[ "$__syskit_powerlevel10k_install_dir" != /* ]]; then
    printf '\033[31m[ERROR]\033[0m Powerlevel10k state is malformed; skipping Powerlevel10k integration: %s\n' \
        "$__syskit_powerlevel10k_state_file" >&2
    unset \
        __syskit_powerlevel10k_state_file \
        __syskit_powerlevel10k_install_dir

    return 0
fi

__syskit_powerlevel10k_theme="$__syskit_powerlevel10k_install_dir/powerlevel10k.zsh-theme"

if [[ ! -f "$__syskit_powerlevel10k_theme" ]] ||
    [[ ! -r "$__syskit_powerlevel10k_theme" ]]; then
    printf '\033[31m[ERROR]\033[0m Powerlevel10k theme is unavailable; skipping Powerlevel10k integration: %s\n' \
        "$__syskit_powerlevel10k_theme" >&2
    unset \
        __syskit_powerlevel10k_state_file \
        __syskit_powerlevel10k_install_dir \
        __syskit_powerlevel10k_theme

    return 0
fi

if ! source "$__syskit_powerlevel10k_theme"; then
    printf '\033[31m[ERROR]\033[0m Failed to initialize Powerlevel10k: %s\n' \
        "$__syskit_powerlevel10k_theme" >&2
fi

unset \
    __syskit_powerlevel10k_state_file \
    __syskit_powerlevel10k_install_dir \
    __syskit_powerlevel10k_theme
