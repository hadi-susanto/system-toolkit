# Check required dependencies
if ! command -v gocatcli >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m gocatcli is not installed; skipping gocatcli completion\n' >&2

    return 0
fi

# The completion script calls compdef; initialize completion when no other module has
if (( ! $+functions[compdef] )); then
    autoload -Uz compinit
    compinit
fi

source <(gocatcli completion zsh)
