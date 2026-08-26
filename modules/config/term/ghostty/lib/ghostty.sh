if (( ${__SYSKIT_GHOSTTY_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_GHOSTTY_LIB_LOADED=1

readonly __GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
readonly __GHOSTTY_CONFIG_FILE="$__GHOSTTY_CONFIG_DIR/config.ghostty"
readonly __GHOSTTY_LOADER_START="# >>> syskit ghostty loader >>>"
readonly __GHOSTTY_LOADER_INCLUDE="config-file = ?syskit.ghostty"
readonly __GHOSTTY_LOADER_END="# <<< syskit ghostty loader <<<"
readonly -a __GHOSTTY_PAYLOAD_FILES=(
    "syskit.ghostty"
)

##
# ghostty_loader_state
#
# Checks whether config.ghostty contains one valid SysKit Ghostty loader block.
#
# Returns:
#   1 when config.ghostty or the managed loader block is absent.
#   2 when loader markers or managed block content are inconsistent.
#
ghostty_loader_state() {
    local has_start=0
    local has_end=0

    if [[ ! -f "$__GHOSTTY_CONFIG_FILE" ]]; then
        return 1
    fi

    if grep -Fqx -- "$__GHOSTTY_LOADER_START" "$__GHOSTTY_CONFIG_FILE"; then
        has_start=1
    fi

    if grep -Fqx -- "$__GHOSTTY_LOADER_END" "$__GHOSTTY_CONFIG_FILE"; then
        has_end=1
    fi

    if (( ! has_start && ! has_end )); then
        return 1
    fi

    if (( has_start != has_end )); then
        return 2
    fi

    if awk \
        -v start="$__GHOSTTY_LOADER_START" \
        -v include_line="$__GHOSTTY_LOADER_INCLUDE" \
        -v end="$__GHOSTTY_LOADER_END" '
            $0 == start {
                if (inside || found) {
                    invalid = 1
                }

                inside = 1
                next
            }

            inside && $0 == include_line {
                if (has_include) {
                    invalid = 1
                }

                has_include = 1
                next
            }

            $0 == end {
                if (!inside || !has_include) {
                    invalid = 1
                }

                inside = 0
                found = 1
                next
            }

            inside {
                invalid = 1
            }

            END {
                valid = found && !inside && !invalid

                if (valid) {
                    exit 0
                }

                exit 1
            }
        ' "$__GHOSTTY_CONFIG_FILE"; then
        return 0
    fi

    return 2
}
