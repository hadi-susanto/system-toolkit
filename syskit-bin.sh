#!/usr/bin/env bash
set -euo pipefail

__script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export SYSKIT_ROOT="$__script_dir"
export COMMON_LIB="$SYSKIT_ROOT/lib/common"
export BIN_LIB="$SYSKIT_ROOT/lib/bin"

main() {
    exec bash "$BIN_LIB/main.sh" "$@"
}

main "$@"
