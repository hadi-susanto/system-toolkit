if (( ${__SYSKIT_KITTY_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_KITTY_LIB_LOADED=1

readonly __KITTY_CONFIG_DIR="$HOME/.config/kitty"
readonly __KITTY_CONFIG_FILE="$__KITTY_CONFIG_DIR/kitty.conf"
readonly __KITTY_LOADER_START="# >>> syskit kitty loader >>>"
readonly __KITTY_LOADER_INCLUDE="globinclude syskit.kitty"
readonly __KITTY_LOADER_END="# <<< syskit kitty loader <<<"
readonly -a __KITTY_PAYLOAD_FILES=(
    "syskit.kitty"
    "syskit.session"
)

##
# kitty_loader_state
#
# Checks whether kitty.conf contains one valid SysKit Kitty loader block.
#
# Returns:
#   1 when kitty.conf or the managed loader block is absent.
#   2 when loader markers or managed block content are inconsistent.
#
kitty_loader_state() {
    local has_start=0
    local has_end=0

    if [[ ! -f "$__KITTY_CONFIG_FILE" ]]; then
        return 1
    fi

    if grep -Fqx -- "$__KITTY_LOADER_START" "$__KITTY_CONFIG_FILE"; then
        has_start=1
    fi

    if grep -Fqx -- "$__KITTY_LOADER_END" "$__KITTY_CONFIG_FILE"; then
        has_end=1
    fi

    if (( ! has_start && ! has_end )); then
        return 1
    fi

    if (( has_start != has_end )); then
        return 2
    fi

    if awk \
        -v start="$__KITTY_LOADER_START" \
        -v include_line="$__KITTY_LOADER_INCLUDE" \
        -v end="$__KITTY_LOADER_END" '
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
        ' "$__KITTY_CONFIG_FILE"; then
        return 0
    fi

    return 2
}
