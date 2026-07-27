#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$CONFIG_LIB/metadata.sh"

main() {
    local -a modules
    local -A metadata
    local -A names=()
    local -A descriptions=()
    local canonical_id
    local index=1

    if (( $# > 0 )); then
        log_error "The list command does not accept arguments"
        bash "$CONFIG_COMMAND/help.sh" list >&2

        return 1
    fi

    list_config_modules modules || return $?

    for canonical_id in "${modules[@]}"; do
        parse_config_metadata "$canonical_id" metadata || return $?
        names["$canonical_id"]="${metadata[NAME]}"
        descriptions["$canonical_id"]="${metadata[DESCRIPTION]}"
    done

    if (( ${#modules[@]} == 0 )); then
        printf 'No configuration modules are available.\n'

        return 0
    fi

    printf 'Available configuration modules\n'
    printf '%s\n' '================================='

    for canonical_id in "${modules[@]}"; do
        printf '%2d. %s %s[id: %s]%s\n' \
            "$index" \
            "${names[$canonical_id]}" \
            "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
        printf '    %s\n' "${descriptions[$canonical_id]}"

        ((index += 1))
    done
}

main "$@"
