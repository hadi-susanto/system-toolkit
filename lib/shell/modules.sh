##
# list_shell_modules <modules_name>
#
# Lists canonical module IDs represented by category/module subdirectories of
# the shell asset directory. Symbolic links and invalid IDs are ignored.
#
# Parameters:
#   modules_name    Name of the indexed array that receives canonical module
#                   IDs.
#
# Returns:
#   1 when the shell payload root is unset, is a symbolic link, or is not a
#   directory.
#
list_shell_modules() {
    local modules_name="$1"
    local -n modules_ref="$modules_name"
    local module_root="${SHELL_PAYLOAD:-}"
    local category_dir
    local module_dir
    local category
    local module
    local canonical_id
    local LC_ALL=C

    modules_ref=()

    if [[ -z "$module_root" ]]; then
        log_error "Shell module directory is not set"

        return 1
    fi

    if [[ -L "$module_root" ]] || [[ ! -d "$module_root" ]]; then
        log_error "Invalid shell module directory: $module_root"

        return 1
    fi

    for category_dir in "$module_root"/*; do
        if [[ ! -d "$category_dir" ]] || [[ -L "$category_dir" ]]; then
            continue
        fi

        category="${category_dir##*/}"

        for module_dir in "$category_dir"/*; do
            if [[ ! -d "$module_dir" ]] || [[ -L "$module_dir" ]]; then
                continue
            fi

            module="${module_dir##*/}"
            canonical_id="$category/$module"

            if ! __valid_shell_module_id "$canonical_id"; then
                log_warn "Skipping invalid shell module ID: $canonical_id"

                continue
            fi

            modules_ref+=("$canonical_id")
        done
    done
}
