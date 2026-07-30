if (( ${__SYSKIT_RESOLVER_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_RESOLVER_LOADED=1

readonly -A __RESOLVER_MODULE_ALIASES=(
    [hide-password-asterisks]="sys/password-asterisks"
    [sys/hide-password-asterisks]="sys/password-asterisks"
)

__resolver_valid_module_name() {
    local module="$1"

    [[ "$module" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

__resolver_valid_canonical_module_id() {
    local canonical_id="$1"

    [[ "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]
}

__resolver_module_exists() {
    local module_root="$1"
    local canonical_id="$2"
    local category_dir="$module_root/${canonical_id%%/*}"
    local module_dir="$module_root/$canonical_id"

    [[ -d "$category_dir" ]] && [[ ! -L "$category_dir" ]] &&
        [[ -d "$module_dir" ]] && [[ ! -L "$module_dir" ]]
}

__resolver_resolve_module_alias() {
    local module_root="$1"
    local alias="$2"
    local canonical_id="${__RESOLVER_MODULE_ALIASES[$alias]:-}"

    if [[ -z "$canonical_id" ]]; then
        return 1
    fi

    if ! __resolver_valid_canonical_module_id "$canonical_id"; then
        return 1
    fi

    if ! __resolver_module_exists "$module_root" "$canonical_id"; then
        return 1
    fi

    printf '%s\n' "$canonical_id"
}

##
# resolve_module <module_root> <module>
#
# Resolves a module name or canonical ID within one category/module root.
# When no direct module is found, a validated internal alias is used.
#
# Parameters:
#   module_root    Directory containing category/module subdirectories.
#   module         Module-name segment, canonical ID, or internal alias.
#
# Output:
#   Prints the resolved canonical module ID.
#
# Returns:
#   1 when the root or module is invalid, no module is found, or an alias maps
#   to an unavailable canonical ID.
#   2 when a module-name segment matches more than one canonical ID.
#
resolve_module() {
    local module_root="$1"
    local module="$2"
    local category_dir
    local category
    local canonical_id
    local -a matches=()
    local LC_ALL=C

    if [[ -z "$module_root" ]] || [[ -L "$module_root" ]] || [[ ! -d "$module_root" ]]; then
        return 1
    fi

    if __resolver_valid_canonical_module_id "$module"; then
        if __resolver_module_exists "$module_root" "$module"; then
            printf '%s\n' "$module"

            return 0
        fi

        __resolver_resolve_module_alias "$module_root" "$module"

        return $?
    fi

    if ! __resolver_valid_module_name "$module"; then
        return 1
    fi

    for category_dir in "$module_root"/*; do
        if [[ ! -d "$category_dir" ]] || [[ -L "$category_dir" ]]; then
            continue
        fi

        category="${category_dir##*/}"
        canonical_id="$category/$module"

        if ! __resolver_valid_canonical_module_id "$canonical_id"; then
            continue
        fi

        if __resolver_module_exists "$module_root" "$canonical_id"; then
            matches+=("$canonical_id")
        fi
    done

    if (( ${#matches[@]} > 1 )); then
        return 2
    fi

    if (( ${#matches[@]} == 1 )); then
        printf '%s\n' "${matches[0]}"

        return 0
    fi

    __resolver_resolve_module_alias "$module_root" "$module"
}
