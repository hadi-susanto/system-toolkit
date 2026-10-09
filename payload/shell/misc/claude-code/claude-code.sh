# Check required dependencies
if ! command -v claude >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m claude is not installed; skipping Claude Code\n' >&2

    return 0
fi

export DISABLE_AUTOUPDATER=1
