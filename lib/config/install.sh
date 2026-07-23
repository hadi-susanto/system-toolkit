#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    validate_no_options install "$@" || {
        bash "$CONFIG_LIB/help.sh" install >&2

        return 1
    }

    printf 'Hello world from the configuration toolkit: install.\n'
}

main "$@"
