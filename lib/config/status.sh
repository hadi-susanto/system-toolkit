#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    validate_no_options status "$@" || {
        bash "$CONFIG_LIB/help.sh" status >&2

        return 1
    }

    printf 'Hello world from the configuration toolkit: status.\n'
}

main "$@"
