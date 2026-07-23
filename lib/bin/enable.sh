#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$BIN_LIB/__scope.sh"

main() {
    local -A options
    local -a args

    parse_bin_scope options args "$@" || {
        bash "$BIN_LIB/help.sh" enable >&2

        return 1
    }

    printf 'Hello world from the binary toolkit: enable.\n'
    printf 'Scope: %s\n' "${options[SCOPE]}"
}

main "$@"
