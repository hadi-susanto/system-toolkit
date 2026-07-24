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

    for source in "$SYSKIT_ROOT/bin"/*; do
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

    source="$SYSKIT_ROOT/bin/$name"

    if [[ ! -f "$source" ]] || [[ -L "$source" ]]; then
        log_error "Unknown SysKit executable: $name"

        return 1
    fi

    printf '%s\n' "$source"
}

##
# bin_checksums_match <source> <target>
#
# Compares two files using SHA-256 checksums.
#
# Parameters:
#   source    SysKit executable source path.
#   target    Installed executable path.
#
# Returns:
#   1 when either checksum cannot be read or the checksums differ.
#
bin_checksums_match() {
    local source="$1"
    local target="$2"
    local source_checksum
    local target_checksum

    source_checksum="$(sha256sum -- "$source" 2>/dev/null)" || return 1
    target_checksum="$(sha256sum -- "$target" 2>/dev/null)" || return 1
    source_checksum="${source_checksum%% *}"
    target_checksum="${target_checksum%% *}"

    [[ "$source_checksum" == "$target_checksum" ]]
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
#   Prints [✗] when absent, [✓] when current, or [↑] when checksums differ.
#
bin_status_marker() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$target" ]] && [[ ! -L "$target" ]]; then
        printf '%s[✗]%s\n' "$COLOR_RED" "$COLOR_RESET"

        return 0
    fi

    if bin_checksums_match "$source" "$target"; then
        printf '%s[✓]%s\n' "$COLOR_GREEN" "$COLOR_RESET"

        return 0
    fi

    printf '%s[↑]%s' "$COLOR_YELLOW" "$COLOR_RESET"
}
