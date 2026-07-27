#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"

main() {
    validate_no_options uninstall "$@" || {
        bash "$CONFIG_LIB/help.sh" uninstall >&2

        return 1
    }

    printf 'Hello world from the configuration toolkit: uninstall.\n'
}

main "$@"
