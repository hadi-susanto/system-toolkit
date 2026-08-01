__valid_shell_module_id() {
    local canonical_id="$1"

    [[ "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]
}

##
# module_delayed <canonical_id>
#
# Checks whether a shell module declares delayed loading through its command
# module marker.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Returns:
#   1 when the marker is absent.
#   2 when the module ID, marker root, or marker type is invalid.
#
module_delayed() {
    local canonical_id="$1"
    local module_root="${SHELL_MODULES:-}"
    local marker

    if [[ -z "$module_root" ]] || [[ -L "$module_root" ]] ||
        [[ ! -d "$module_root" ]]; then
        log_error "Invalid shell command module directory: ${module_root:-<missing>}"

        return 2
    fi

    if ! __valid_shell_module_id "$canonical_id"; then
        log_error "Invalid shell module ID: $canonical_id"

        return 2
    fi

    marker="$module_root/$canonical_id/.delayed"

    if [[ ! -e "$marker" ]] && [[ ! -L "$marker" ]]; then
        return 1
    fi

    if [[ -L "$marker" ]] || [[ ! -f "$marker" ]]; then
        log_error "Invalid delayed shell module marker: $marker"

        return 2
    fi
}

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
