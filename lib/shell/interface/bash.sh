readonly BASH_BASE_DIR="$HOME/.local/share/syskit/bash"

##
# support_module <canonical_id>
#
# Checks whether a module provides a Bash-specific or generic source file.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Returns:
#   1 when no compatible source file exists.
#
support_module() {
    local canonical_id="$1"
    local module_name="${canonical_id##*/}"

    if [[ -f "$SHELL_PAYLOAD/$canonical_id/$module_name.bash" ]]; then
        return 0
    fi

    [[ -f "$SHELL_PAYLOAD/$canonical_id/$module_name.sh" ]]
}

##
# module_installed <canonical_id>
#
# Checks whether a Bash-compatible module is installed.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Returns:
#   1 when neither a Bash-specific nor generic installed file exists.
#
module_installed() {
    local canonical_id="$1"
    local installed_name="${canonical_id//\//_}"

    if [[ -f "$BASH_BASE_DIR/module.d/$installed_name.bash" ]]; then
        return 0
    fi

    [[ -f "$BASH_BASE_DIR/module.d/$installed_name.sh" ]]
}

##
# install_module <canonical_id>
#
# Installs the preferred Bash-compatible source for a module.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Returns:
#   1 when no compatible source exists or the file cannot be installed.
#
install_module() {
    local canonical_id="$1"
    local module_name="${canonical_id##*/}"
    local installed_name="${canonical_id//\//_}"
    local source="$SHELL_PAYLOAD/$canonical_id/$module_name.bash"
    local install_dir="$BASH_BASE_DIR/module.d"
    local target="$install_dir/$installed_name.bash"

    if [[ ! -f "$source" ]]; then
        source="$SHELL_PAYLOAD/$canonical_id/$module_name.sh"
    fi

    if [[ ! -f "$source" ]]; then
        log_error "No Bash-compatible source is available for module: $canonical_id"

        return 1
    fi

    if ! install -d -m 0755 -- "$install_dir"; then
        log_error "Failed to create Bash module directory: $install_dir"

        return 1
    fi

    if ! install -m 0644 -- "$source" "$target"; then
        log_error "Failed to install Bash module: $canonical_id"

        return 1
    fi
}

##
# installed_module_path <canonical_id>
#
# Returns the path to the installed Bash module source file.
# This function behaves similarly to `installed_module`, except
# that it prints the resolved module path instead of returning
# only an exit status.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Output:
#   Full path to the installed Bash module source file.
#
# Returns:
#   1 when the module is not installed.
#
installed_module_path() {
    local canonical_id="$1"
    local installed_name="${canonical_id//\//_}"
    local path="$BASH_BASE_DIR/module.d/$installed_name.bash"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    path="$BASH_BASE_DIR/module.d/$installed_name.sh"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    return 1
}

##
# module_source_path <canonical_id>
#
# Returns the preferred compatible source file for a shell module.
# A shell-specific source file is preferred over the generic source file.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Output:
#   Full path to the preferred compatible source file.
#
# Returns:
#   1 when no compatible source file exists.
#
module_source_path() {
    local canonical_id="$1"
    local module_name="${canonical_id##*/}"
    local path="$SHELL_PAYLOAD/$canonical_id/$module_name.bash"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    path="$SHELL_PAYLOAD/$canonical_id/$module_name.sh"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    return 1
}

##
# uninstall_module <canonical_id>
#
# Removes every installed Bash-compatible file for a module.
#
# Parameters:
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Returns:
#   A non-zero status when an installed file cannot be removed.
#
uninstall_module() {
    local canonical_id="$1"
    local installed_name="${canonical_id//\//_}"
    local module_dir="$BASH_BASE_DIR/module.d"
    local extension
    local file
    local failed=0

    for extension in bash sh; do
        file="$module_dir/$installed_name.$extension"

        if [[ ! -e "$file" ]] && [[ ! -L "$file" ]]; then
            continue
        fi

        if ! rm -f -- "$file"; then
            log_error "Failed to remove Bash module file: $file"
            failed=1
        fi
    done

    return "$failed"
}

##
# loader_active
#
# Checks whether the Bash loader file and its shell startup marker exist.
#
# Returns:
#   1 when the loader, ~/.bashrc, or both managed markers are absent.
#
loader_active() {
    local loader="$BASH_BASE_DIR/loader.sh"
    local startup_file="$HOME/.bashrc"
    local start_marker="# >>> syskit bash loader >>>"
    local end_marker="# <<< syskit bash loader <<<"

    [[ -f "$loader" ]] || return 1
    [[ -f "$startup_file" ]] || return 1

    local has_start=0
    local has_end=0

    if grep -Fqx -- "$start_marker" "$startup_file"; then
        has_start=1
    fi

    if grep -Fqx -- "$end_marker" "$startup_file"; then
        has_end=1
    fi

    if (( has_start && has_end )); then
        return 0
    fi

    if (( ! has_start && ! has_end )); then
        return 1
    fi

    log_warn "Bash loader markers are inconsistent; manual cleanup may be required"

    return 0
}

##
# activate_loader
#
# Creates the Bash module loader and adds its managed block to ~/.bashrc.
#
# Returns:
#   1 when the loader or startup file cannot be written, or when an incomplete
#   managed block prevents a safe update.
#
activate_loader() {
    local loader="$BASH_BASE_DIR/loader.sh"
    local startup_file="$HOME/.bashrc"
    local start_marker="# >>> syskit bash loader >>>"
    local end_marker="# <<< syskit bash loader <<<"
    local loader_tmp
    local startup_tmp
    local last_byte
    local has_start=0
    local has_end=0

    if [[ -L "$startup_file" ]]; then
        if ! startup_file="$(readlink -f -- "$startup_file")"; then
            log_error "Failed to resolve Bash startup symlink: $HOME/.bashrc"

            return 1
        fi
    fi

    if [[ -f "$startup_file" ]]; then
        if grep -Fqx -- "$start_marker" "$startup_file"; then
            has_start=1
        fi

        if grep -Fqx -- "$end_marker" "$startup_file"; then
            has_end=1
        fi
    fi

    if (( has_start != has_end )); then
        log_error "Cannot safely replace an incomplete SysKit Bash loader block: $startup_file"

        return 1
    fi

    if ! install -d -m 0755 -- "$BASH_BASE_DIR"; then
        log_error "Failed to create Bash loader directory: $BASH_BASE_DIR"

        return 1
    fi

    if ! loader_tmp="$(mktemp "$loader.XXXXXX")"; then
        log_error "Failed to create a temporary Bash loader"

        return 1
    fi

    if ! cat >"$loader_tmp" <<'EOF'
for __syskit_module_file in "$HOME/.local/share/syskit/bash/module.d"/*; do
    if [[ ! -f "$__syskit_module_file" ]]; then
        continue
    fi

    case "$__syskit_module_file" in
        *.bash | *.sh)
            source "$__syskit_module_file"
            ;;
        *)
            printf '\033[0;33m[WARN]\033[0m Found non module file: %s\n' \
                "$__syskit_module_file" >&2
            ;;
    esac
done

unset __syskit_module_file
EOF
    then
        log_error "Failed to write the temporary Bash loader"
        rm -f -- "$loader_tmp"

        return 1
    fi

    if ! chmod 0644 -- "$loader_tmp"; then
        log_error "Failed to set Bash loader permissions: $loader_tmp"
        rm -f -- "$loader_tmp"

        return 1
    fi

    if ! mv -f -- "$loader_tmp" "$loader"; then
        log_error "Failed to install Bash loader: $loader"
        rm -f -- "$loader_tmp"

        return 1
    fi

    if [[ ! -e "$startup_file" ]] && ! install -m 0644 -- /dev/null "$startup_file"; then
        log_error "Failed to create Bash startup file: $startup_file"

        return 1
    fi

    if [[ ! -f "$startup_file" ]]; then
        log_error "Bash startup path is not a regular file: $startup_file"

        return 1
    fi

    if ! startup_tmp="$(mktemp "$startup_file.XXXXXX")"; then
        log_error "Failed to create a temporary Bash startup file"

        return 1
    fi

    if (( has_start )); then
        # in this line both has_start and has_end is true.
        if ! awk -v start="$start_marker" -v end="$end_marker" '
            $0 == start { managed = 1; next }
            managed && $0 == end { managed = 0; next }
            !managed { print }
        ' "$startup_file" >"$startup_tmp"; then
            log_error "Failed to remove the existing SysKit Bash loader block"
            rm -f -- "$startup_tmp"

            return 1
        fi
    elif ! cat -- "$startup_file" >"$startup_tmp"; then
        log_error "Failed to copy Bash startup file: $startup_file"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if [[ -s "$startup_tmp" ]]; then
        if ! last_byte="$(tail -c 1 -- "$startup_tmp")"; then
            log_error "Failed to inspect the temporary Bash startup file"
            rm -f -- "$startup_tmp"

            return 1
        fi

        # Command substitution strips trailing newlines, so last_byte is empty
        # if the file already ends with '\n'.
        if [[ -n "$last_byte" ]] && ! printf '\n' >>"$startup_tmp"; then
            log_error "Failed to terminate the existing Bash startup content"
            rm -f -- "$startup_tmp"

            return 1
        fi
    fi

    if ! printf '%s\n' \
        "$start_marker" \
        "# Do not delete either SysKit loader marker. Add custom code after the end marker." \
        '__syskit_loader="$HOME/.local/share/syskit/bash/loader.sh"' \
        'if [[ -f "$__syskit_loader" ]]; then' \
        '    source "$__syskit_loader"' \
        'else' \
        '    printf "%s\n" "SysKit inconsistency detected: loader activation exists in .bashrc, but the loader file is missing. Manual cleanup may be required." >&2' \
        'fi' \
        'unset __syskit_loader' \
        "$end_marker" >>"$startup_tmp"; then
        log_error "Failed to append the SysKit Bash loader block"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! chmod --reference="$startup_file" "$startup_tmp"; then
        log_error "Failed to preserve Bash startup file permissions"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! mv -f -- "$startup_tmp" "$startup_file"; then
        log_error "Failed to update Bash startup file: $startup_file"
        rm -f -- "$startup_tmp"

        return 1
    fi
}

##
# deactivate_loader
#
# Removes the Bash loader and, when both markers exist, atomically removes its
# managed block from ~/.bashrc.
#
# Returns:
#   1 when cleanup fails or only one managed marker exists.
#
deactivate_loader() {
    local loader="$BASH_BASE_DIR/loader.sh"
    local startup_file="$HOME/.bashrc"
    local start_marker="# >>> syskit bash loader >>>"
    local end_marker="# <<< syskit bash loader <<<"
    local startup_tmp
    local has_start=0
    local has_end=0

    if [[ -L "$startup_file" ]]; then
        if ! startup_file="$(readlink -f -- "$startup_file")"; then
            log_error "Failed to resolve Bash startup symlink: $HOME/.bashrc"

            return 1
        fi
    fi

    if [[ ! -f "$startup_file" ]]; then
        if [[ -f "$loader" ]] && ! rm -f -- "$loader"; then
            log_warn ".bashrc does not load the SysKit loader, but the loader file could not be removed."
            log_warn "The leftover file will not affect Bash and can be safely ignored."
        fi

        return 0
    fi

    if grep -Fqx -- "$start_marker" "$startup_file"; then
        has_start=1
    fi

    if grep -Fqx -- "$end_marker" "$startup_file"; then
        has_end=1
    fi

    if (( ! has_start && ! has_end )); then
        if [[ -f "$loader" ]] && ! rm -f -- "$loader"; then
            log_warn ".bashrc does not load the SysKit loader, but the loader file could not be removed."
            log_warn "The leftover file will not affect Bash and can be safely ignored."
        fi

        return 0
    fi

    if (( has_start != has_end )); then
        log_error "Cannot safely remove an incomplete SysKit Bash loader block: $startup_file"

        return 1
    fi

    if ! startup_tmp="$(mktemp "$startup_file.XXXXXX")"; then
        log_error "Failed to create a temporary Bash startup file"

        return 1
    fi

    if ! awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { managed = 1; next }
        managed && $0 == end { managed = 0; next }
        !managed { print }
    ' "$startup_file" >"$startup_tmp"; then
        log_error "Failed to remove the SysKit Bash loader block"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! chmod --reference="$startup_file" "$startup_tmp"; then
        log_error "Failed to preserve Bash startup file permissions"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! mv -f -- "$startup_tmp" "$startup_file"; then
        log_error "Failed to update Bash startup file: $startup_file"
        rm -f -- "$startup_tmp"

        return 1
    fi

    # Ignore missing loader files so this function is idempotent.
    if [[ -f "$loader" ]] && ! rm -f -- "$loader"; then
        log_error "Failed to remove Bash loader: $loader"

        return 1
    fi

    return 0
}
