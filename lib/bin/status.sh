#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    validate_no_options status "$@" || {
        bash "$BIN_LIB/help.sh" status >&2

        return 1
    }

    printf 'Hello world from the binary toolkit: status.\n'
}

main "$@"
