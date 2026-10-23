# Check required dependencies
if ! command -v pay-respects >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m pay-respects is not installed; skipping pay-respects\n' >&2

    return 0
fi

export _PR_AI_DISABLE="${_PR_AI_DISABLE:-1}"

eval "$(pay-respects zsh --alias)"
