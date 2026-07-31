# Check required dependencies
if ! command -v oh-my-posh >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m oh-my-posh is not installed; skipping Oh My Posh integration\n' >&2

    return 0
fi

eval "$(oh-my-posh init bash)"
