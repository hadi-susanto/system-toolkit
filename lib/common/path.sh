#!/usr/bin/env bash

if [[ -n "${_SYSKIT_PATH_LOADED:-}" ]]; then
    return 0
fi

readonly _SYSKIT_PATH_LOADED=1

source "$COMMON_LIB/common.sh"

##
# expand_path
#
# Expands a path into an absolute, normalized path.
#
# A leading ~ refers to the current user's HOME. Other user-home forms such as
# ~other-user are not supported. Environment variables and shell expressions
# are not evaluated.
#
# Parameters:
#   path - Non-empty path to expand.
#
# Output:
#   Prints the expanded absolute path.
#
# Return:
#   1 - The path, HOME, or current working directory is invalid, or expansion
#       failed.
#
expand_path() {
    local path="$1"
    local expanded_path

    if [[ "$path" == *$'\n'* || "$path" == *$'\r'* ]]; then
        log_error "Path must be single-line"

        return 1
    fi

    case "$path" in
        "~")
            if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
                log_error "HOME must be set to an absolute path"

                return 1
            fi

            path="$HOME"
            ;;
        "~/"*)
            if [[ -z "${HOME:-}" || "$HOME" != /* ]]; then
                log_error "HOME must be set to an absolute path"

                return 1
            fi

            path="$HOME/${path:2}"
            ;;
        "~"*)
            log_error "User-specific home expansion is not supported: $path"

            return 1
            ;;
    esac

    if [[ "$path" != /* ]]; then
        if [[ -z "${PWD:-}" || "$PWD" != /* ]]; then
            log_error "The current working directory must be absolute"

            return 1
        fi

        path="$PWD/$path"
    fi

    if ! expanded_path="$(realpath -m -- "$path")"; then
        log_error "Failed to expand path: $path"

        return 1
    fi

    printf '%s\n' "$expanded_path"
}

##
# can_write <target>
#
# Checks whether an existing path is writable or a missing path can be created
# beneath its nearest existing writable ancestor.
#
# Parameters:
#   target - Existing path or prospective path to inspect.
#
# Return:
#   0 - The target is writable or can be created.
#   1 - The argument is invalid or no writable target or ancestor exists.
#
can_write() {
    local target="$1"
    local directory
    local parent

    target="$(expand_path "$target")" || return $?

    if [[ -e "$target" ]]; then
        if [[ -d "$target" ]]; then
            [[ -w "$target" && -x "$target" ]]
        else
            [[ -w "$target" ]]
        fi

        return
    fi

    directory="$(dirname -- "$target")" || return 1

    while [[ ! -d "$directory" ]]; do
        parent="$(dirname -- "$directory")" || return 1
        [[ "$parent" != "$directory" ]] || return 1
        directory="$parent"
    done

    [[ -w "$directory" && -x "$directory" ]]
}
