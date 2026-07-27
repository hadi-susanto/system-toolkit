##
# local_install_dir
#
# Resolves the directory used for current-user executable installations.
#
# Output:
#   Prints the local installation directory.
#
# Returns:
#   1 when HOME is unavailable.
#
local_install_dir() {
    if [[ -z "${HOME:-}" ]]; then
        printf 'HOME is required to resolve the local installation directory\n' >&2

        return 1
    fi

    printf '%s\n' "$HOME/.local/bin"
}

##
# global_install_dir
#
# Resolves the directory used for system-wide executable installations.
#
# Output:
#   Prints the global installation directory.
#
global_install_dir() {
    printf '%s\n' '/usr/local/bin'
}

##
# install_dir_in_path <install_dir>
#
# Checks whether an installation directory is present in PATH.
#
# Parameters:
#   install_dir    Installation directory to find.
#
# Returns:
#   1 when the directory is absent from PATH.
#
install_dir_in_path() {
    local install_dir="$1"
    local -a path_entries
    local path_entry
    local IFS=':'

    read -r -a path_entries <<<"${PATH:-}"

    for path_entry in "${path_entries[@]}"; do
        if [[ "$path_entry" == "$install_dir" ]]; then
            return 0
        fi
    done

    return 1
}
