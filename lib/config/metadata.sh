if (( ${__SYSKIT_CONFIG_METADATA_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_CONFIG_METADATA_LOADED=1

__trim_config_metadata_value() {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s\n' "$value"
}

__valid_config_module_id() {
    local canonical_id="$1"

    [[ "$canonical_id" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]
}

##
# list_config_modules <modules_name>
#
# Lists configuration module IDs represented by self-contained
# category/module directories. Symbolic links are ignored. Directories with
# invalid canonical module IDs are skipped with a warning.
#
# Parameters:
#   modules_name    Name of the indexed array that receives canonical module
#                   IDs.
#
# Returns:
#   1 when the configuration module root is unset, is a symbolic link, or is
#   not a directory.
#
list_config_modules() {
    local modules_name="$1"
    local -n modules_ref="$modules_name"
    local module_root="${CONFIG_MODULES:-}"
    local category_dir
    local module_dir
    local category
    local module
    local canonical_id
    local LC_ALL=C

    modules_ref=()

    if [[ -z "$module_root" ]]; then
        log_error "Configuration module directory is not set"

        return 1
    fi

    if [[ -L "$module_root" ]]; then
        log_error "Invalid configuration module directory: $module_root"

        return 1
    fi

    if [[ ! -e "$module_root" ]]; then
        return 0
    fi

    if [[ ! -d "$module_root" ]]; then
        log_error "Invalid configuration module directory: $module_root"

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

            if ! __valid_config_module_id "$canonical_id"; then
                log_warn "Skipping invalid configuration module ID: $canonical_id"

                continue
            fi

            modules_ref+=("$canonical_id")
        done
    done
}

##
# parse_config_metadata <canonical_id> <metadata_name>
#
# Parses one module's metadata.conf without executing it as shell code.
#
# Parameters:
#   canonical_id    Module ID in <category>/<module> format.
#   metadata_name   Name of the associative array that receives metadata.
#
# Returns:
#   1 when the ID, module directory, metadata syntax, or required metadata is
#   invalid.
#
parse_config_metadata() {
    local canonical_id="$1"
    local metadata_name="$2"
    local -n metadata_ref="$metadata_name"
    local module_root="${CONFIG_MODULES:-}"
    local category_dir
    local module_dir
    local metadata_file
    local line
    local key
    local value
    local line_number=0
    local required_key
    local -A seen=()
    local -a required_keys=(
        "NAME"
        "DESCRIPTION"
    )

    metadata_ref=()

    if [[ -z "$module_root" ]]; then
        log_error "Configuration module directory is not set"

        return 1
    fi

    if ! __valid_config_module_id "$canonical_id"; then
        log_error "Invalid configuration module ID: $canonical_id"

        return 1
    fi

    category_dir="$module_root/${canonical_id%%/*}"
    module_dir="$module_root/$canonical_id"
    metadata_file="$module_dir/metadata.conf"

    if [[ ! -d "$category_dir" ]] || [[ -L "$category_dir" ]]; then
        log_error "Configuration category not found: ${canonical_id%%/*}"

        return 1
    fi

    if [[ ! -d "$module_dir" ]] || [[ -L "$module_dir" ]]; then
        log_error "Configuration module not found: $canonical_id"

        return 1
    fi

    if [[ ! -f "$metadata_file" ]] || [[ -L "$metadata_file" ]]; then
        log_error "Configuration metadata not found: $metadata_file"

        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number += 1))
        line="${line%$'\r'}"
        line="$(__trim_config_metadata_value "$line")"

        if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
            continue
        fi

        if [[ "$line" != *=* ]]; then
            log_error "Invalid metadata at $metadata_file:$line_number"

            return 1
        fi

        key="$(__trim_config_metadata_value "${line%%=*}")"
        value="$(__trim_config_metadata_value "${line#*=}")"

        if [[ ! "$key" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
            log_error "Invalid metadata key at $metadata_file:$line_number: $key"

            return 1
        fi

        if [[ -n "${seen[$key]:-}" ]]; then
            log_error "Duplicate metadata key at $metadata_file:$line_number: $key"

            return 1
        fi

        if [[ "$value" == \"* || "$value" == *\" ]]; then
            if [[ "$value" != \"*\" ]] || (( ${#value} < 2 )); then
                log_error "Invalid quoted metadata value at $metadata_file:$line_number"

                return 1
            fi

            value="${value:1:${#value}-2}"
        fi

        metadata_ref["$key"]="$value"
        seen["$key"]=1
    done < "$metadata_file"

    for required_key in "${required_keys[@]}"; do
        if [[ -z "${metadata_ref[$required_key]:-}" ]]; then
            log_error "Missing required metadata key in $metadata_file: $required_key"

            return 1
        fi
    done
}
