# Check required dependencies
if ! command -v kubectl >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m kubectl is not installed; skipping kubectl completion\n' >&2

    return 0
fi

# The completion script calls compdef; initialize completion when no other module has
if (( ! $+functions[compdef] )); then
    autoload -Uz compinit
    compinit
fi

source <(kubectl completion zsh)
