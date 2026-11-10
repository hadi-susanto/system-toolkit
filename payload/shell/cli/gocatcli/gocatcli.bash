# Check required dependencies
if ! command -v gocatcli >/dev/null 2>&1; then
    printf '\033[31m[ERROR]\033[0m gocatcli is not installed; skipping gocatcli completion\n' >&2

    return 0
fi

source <(gocatcli completion bash)
