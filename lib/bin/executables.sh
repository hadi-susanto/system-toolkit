##
# list_bin_executables <names_name>
#
# Lists the extensionless regular files available in the SysKit bin directory.
#
# Parameters:
#   names_name    Name of the indexed array that receives executable names.
#
list_bin_executables() {
    local names_name="$1"
    local -n names_ref="$names_name"
    local source
    local name

    names_ref=()

    for source in "$BIN_PAYLOAD"/*; do
        if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
            continue
        fi

        name="${source##*/}"

        if [[ "$name" == -* ]] || [[ "$name" == *.* ]] || [[ "$name" == "all" ]]; then
            continue
        fi

        names_ref+=("$name")
    done
}

##
# resolve_bin_executable <name>
#
# Resolves an exact executable name to its SysKit source file.
#
# Parameters:
#   name    Extensionless executable name.
#
# Output:
#   Prints the executable source path.
#
# Returns:
#   1 when the name is unsafe or does not identify an available executable.
#
resolve_bin_executable() {
    local name="$1"
    local source

    if [[ -z "$name" ]] || [[ "$name" == "all" ]] || [[ "$name" == -* ]] ||
        [[ "$name" == */* ]] || [[ "$name" == *.* ]]; then
        log_error "Invalid executable name: $name"

        return 1
    fi

    source="${BIN_PAYLOAD}/${name}"

    if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
        log_error "Unknown SysKit executable: $name"

        return 1
    fi

    printf '%s\n' "$source"
}

##
# bin_status_marker <source> <target>
#
# Resolves the installation marker for a SysKit executable.
#
# Parameters:
#   source    SysKit executable source path.
#   target    Expected installed executable path.
#
# Output:
#   Prints [✗] when absent, [✓] when current, [↑] when checksums differ, or
#   [?] when a checksum cannot be calculated.
#
# Returns:
#   2 when the source checksum cannot be read.
#   3 when the target checksum cannot be read.
#   127 when sha256sum is unavailable.
#
bin_status_marker() {
    local source="$1"
    local target="$2"
    local checksum_status=0

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        printf '%s[✗]%s\n' "$COLOR_RED" "$COLOR_RESET"

        return 0
    fi

    if checksums_match "$source" "$target"; then
        checksum_status=0
    else
        checksum_status=$?
    fi

    case "$checksum_status" in
        0)
            printf '%s[✓]%s\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[↑]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
        2 | 3 | 127)
            printf '%s[?]%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return "$checksum_status"
            ;;
    esac
}
