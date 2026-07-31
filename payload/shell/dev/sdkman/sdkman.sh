__syskit_sdkman_state_file="$HOME/.local/state/syskit/dev/sdkman/install-dir"

if [[ -L "$__syskit_sdkman_state_file" ]] ||
    [[ ! -f "$__syskit_sdkman_state_file" ]] ||
    [[ ! -r "$__syskit_sdkman_state_file" ]]; then
    printf '\033[31m[ERROR]\033[0m SDKMAN! state is unavailable; skipping SDKMAN! integration: %s\n' \
        "$__syskit_sdkman_state_file" >&2
    unset __syskit_sdkman_state_file

    return 0
fi

if ! IFS= read -r __syskit_sdkman_install_dir <"$__syskit_sdkman_state_file" ||
    [[ -z "$__syskit_sdkman_install_dir" ]] ||
    [[ "$__syskit_sdkman_install_dir" != /* ]]; then
    printf '\033[31m[ERROR]\033[0m SDKMAN! state is malformed; skipping SDKMAN! integration: %s\n' \
        "$__syskit_sdkman_state_file" >&2
    unset __syskit_sdkman_state_file __syskit_sdkman_install_dir

    return 0
fi

__syskit_sdkman_init="$__syskit_sdkman_install_dir/bin/sdkman-init.sh"

if [[ ! -f "$__syskit_sdkman_init" ]] ||
    [[ ! -r "$__syskit_sdkman_init" ]]; then
    printf '\033[31m[ERROR]\033[0m SDKMAN! initialization is unavailable; skipping SDKMAN! integration: %s\n' \
        "$__syskit_sdkman_init" >&2
    unset \
        __syskit_sdkman_state_file \
        __syskit_sdkman_install_dir \
        __syskit_sdkman_init

    return 0
fi

export SDKMAN_DIR="$__syskit_sdkman_install_dir"

if ! source "$__syskit_sdkman_init"; then
    printf '\033[31m[ERROR]\033[0m Failed to initialize SDKMAN!: %s\n' \
        "$__syskit_sdkman_init" >&2
fi

unset \
    __syskit_sdkman_state_file \
    __syskit_sdkman_install_dir \
    __syskit_sdkman_init
