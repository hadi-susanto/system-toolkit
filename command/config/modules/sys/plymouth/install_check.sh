#!/usr/bin/env bash
set -euo pipefail

source "$CONFIG_LIB/checks.sh"

main() {
    return "$CONFIG_CHECK_BLOCK"
}

main "$@"
