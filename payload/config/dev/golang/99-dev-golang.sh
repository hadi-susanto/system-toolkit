# Managed by SysKit (dev/golang)
__syskit_golang_state_file="$HOME/.local/state/syskit/dev/golang/gobin"
if [ -z "${GOBIN:-}" ] && [ -f "$__syskit_golang_state_file" ] && [ -r "$__syskit_golang_state_file" ]; then
    __syskit_golang_gobin=""
    IFS= read -r __syskit_golang_gobin <"$__syskit_golang_state_file" || :
    case "$__syskit_golang_gobin" in
        /*) GOBIN="$__syskit_golang_gobin"; export GOBIN ;;
    esac
    unset __syskit_golang_gobin
fi
unset __syskit_golang_state_file

if [ -n "${GOBIN:-}" ]; then
    case ":$PATH:" in
        *":$GOBIN:"*) ;;
        *) PATH="$GOBIN:$PATH"; export PATH ;;
    esac
fi
