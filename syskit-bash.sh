#!/usr/bin/env bash
set -euo pipefail

__script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export SYSKIT_ROOT="$__script_dir"
export COMMON_LIB="$SYSKIT_ROOT/lib/common"
export SHELL_LIB="$SYSKIT_ROOT/lib/shell"

main() {
    exec bash "$SHELL_LIB/main.sh" bash "$@"
}

main "$@"
