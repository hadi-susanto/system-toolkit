##
# list_shell_modules <modules_name>
#
# Lists module names represented by direct subdirectories of the shell asset
# directory.
#
# Parameters:
#   modules_name    Name of the indexed array that receives module names.
#
list_shell_modules() {
    local modules_name="$1"
    local -n modules_ref="$modules_name"
    local source
    local module

    modules_ref=()

    for source in "$SHELL_DIR"/*; do
        if [[ ! -d "$source" ]] || [[ -L "$source" ]]; then
            continue
        fi

        module="${source##*/}"

        if [[ "$module" == -* ]] || [[ "$module" == "all" ]]; then
            continue
        fi

        modules_ref+=("$module")
    done
}

##
# resolve_shell_module <name>
#
# Resolves an exact folder path of shell module.
#
# Parameters:
#   name    Module name.
#
# Output:
#   Prints the module source folder path.
#
# Returns:
#   1 when the name is unsafe or does not identify an available module.
#
resolve_shell_module() {
    local name="$1"
    local source

    if [[ -z "$module" ]] || [[ "$module" == "." ]] ||
        [[ "$module" == ".." ]] || [[ "$module" == "all" ]] ||
        [[ "$module" == -* ]] || [[ "$module" == */* ]]; then
        log_error "Invalid shell module name: $module"

        return 1
    fi

    source="$SYSKIT_ROOT/shell/$name"

    if [[ ! -d "$source" ]] || [[ -L "$source" ]]; then
        log_error "Unknown shell module name: $name"

        return 1
    fi

    printf '%s\n' "$source"
}
