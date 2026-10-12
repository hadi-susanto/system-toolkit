#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    local shell="${1:-}"

    if [[ "$shell" != "bash" ]]; then
        log_error "Partial directory completion supports only Bash: ${shell:-<missing>}"

        return 1
    fi
}

main "$@"
