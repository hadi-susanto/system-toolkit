# Check required dependencies
if ! command -v gocatcli-ex >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m gocatcli-ex is not installed; skipping gocatcli-ex completion\n' >&2

    return 0
fi

source <(gocatcli-ex completion bash)
