#!/usr/bin/env bash
set -euo pipefail

__script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export SYSKIT_ROOT="$__script_dir"
export COMMON_LIB="$SYSKIT_ROOT/lib/common"
export CONFIG_LIB="$SYSKIT_ROOT/lib/config"

main() {
    exec bash "$CONFIG_LIB/main.sh" "$@"
}

main "$@"
