# Managed by SysKit (dev/mise)
__syskit_mise_state_file="$HOME/.local/state/syskit/dev/mise/data-dir"
if [ -z "${MISE_DATA_DIR:-}" ] && [ -f "$__syskit_mise_state_file" ] && [ -r "$__syskit_mise_state_file" ]; then
    __syskit_mise_data_dir=""
    IFS= read -r __syskit_mise_data_dir <"$__syskit_mise_state_file" || :
    case "$__syskit_mise_data_dir" in
        /*) MISE_DATA_DIR="$__syskit_mise_data_dir"; export MISE_DATA_DIR ;;
    esac
    unset __syskit_mise_data_dir
fi
unset __syskit_mise_state_file

__syskit_mise_shims="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
if [ -d "$__syskit_mise_shims" ]; then
    case ":$PATH:" in
        *":$__syskit_mise_shims:"*) ;;
        *) PATH="$__syskit_mise_shims:$PATH"; export PATH ;;
    esac
fi
unset __syskit_mise_shims
