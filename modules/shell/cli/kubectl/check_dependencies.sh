#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl is required before its shell integration can be installed"

        return 1
    fi
}

main "$@"
