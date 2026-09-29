# Check required dependencies
if ! command -v mise >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m mise is not installed; skipping Mise\n' >&2

    return 0
fi

__syskit_mise_state_file="$HOME/.local/state/syskit/dev/mise/data-dir"
__syskit_mise_data_dir=""

if [[ -r "$__syskit_mise_state_file" ]]; then
    __syskit_mise_data_dir="$(<"$__syskit_mise_state_file")"
fi

if [[ -n "$__syskit_mise_data_dir" ]]; then
    if [[ "$__syskit_mise_data_dir" != /* ]]; then
        printf '\033[31m[ERROR]\033[0m Invalid mise data directory config, please rerun syskit-cfg mise\n' >&2

        return 0
    fi

    export MISE_DATA_DIR="$__syskit_mise_data_dir"
fi

if [[ -n "$BASH_VERSION" ]]; then
    eval "$(mise activate bash)"
elif [[ -n "$ZSH_VERSION" ]]; then
    eval "$(mise activate zsh)"
else
    printf '\033[33m[WARN]\033[0m unsupported shell; skipping Mise activation\n' >&2
fi
