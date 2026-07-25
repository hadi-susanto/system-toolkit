##
# support_module <module>
#
# Checks whether a module provides a Bash-specific or generic source file.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   1 when no compatible source file exists.
#
support_module() {
    local module="$1"

    if [[ -f "$SHELL_DIR/$module/$module.bash" ]]; then
        return 0
    fi

    [[ -f "$SHELL_DIR/$module/$module.sh" ]]
}

##
# module_installed <module>
#
# Checks whether a Bash-compatible module is installed.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   1 when neither a Bash-specific nor generic installed file exists.
#
module_installed() {
    local module="$1"

    if [[ -f "$HOME/.local/share/syskit/bash/module.d/$module.bash" ]]; then
        return 0
    fi

    [[ -f "$HOME/.local/share/syskit/bash/module.d/$module.sh" ]]
}

##
# install_module <module>
#
# Installs the preferred Bash-compatible source for a module.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   1 when no compatible source exists or the file cannot be installed.
#
install_module() {
    local module="$1"
    local source="$SHELL_DIR/$module/$module.bash"
    local install_dir="$HOME/.local/share/syskit/bash/module.d"

    if [[ ! -f "$source" ]]; then
        source="$SHELL_DIR/$module/$module.sh"
    fi

    if [[ ! -f "$source" ]]; then
        log_error "No Bash-compatible source is available for module: $module"

        return 1
    fi

    if ! install -d -m 0755 -- "$install_dir"; then
        log_error "Failed to create Bash module directory: $install_dir"

        return 1
    fi

    if ! install -m 0644 -- "$source" "$install_dir/${source##*/}"; then
        log_error "Failed to install Bash module: $module"

        return 1
    fi
}

##
# uninstall_module <module>
#
# Removes every installed Bash-compatible file for a module.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   A non-zero status when an installed file cannot be removed.
#
uninstall_module() {
    local module="$1"
    local module_dir="$HOME/.local/share/syskit/bash/module.d"
    local extension
    local file
    local failed=0

    for extension in bash sh; do
        file="$module_dir/$module.$extension"

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
    local loader="$HOME/.local/share/syskit/bash/loader.sh"
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
    local loader_dir="$HOME/.local/share/syskit/bash"
    local loader="$loader_dir/loader.sh"
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

    if ! install -d -m 0755 -- "$loader_dir"; then
        log_error "Failed to create Bash loader directory: $loader_dir"

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
    local loader="$HOME/.local/share/syskit/bash/loader.sh"
    local startup_file="$HOME/.bashrc"
    local start_marker="# >>> syskit bash loader >>>"
    local end_marker="# <<< syskit bash loader <<<"
    local startup_tmp
    local has_start=0
    local has_end=0

    # Ignore missing loader files so this function is idempotent.
    if [[ -f "$loader" ]] && ! rm -f -- "$loader"; then
        log_error "Failed to remove Bash loader: $loader"

        return 1
    fi

    if [[ -L "$startup_file" ]]; then
        if ! startup_file="$(readlink -f -- "$startup_file")"; then
            log_error "Failed to resolve Bash startup symlink: $HOME/.bashrc"

            return 1
        fi
    fi

    if [[ ! -f "$startup_file" ]]; then
        return 0
    fi

    if grep -Fqx -- "$start_marker" "$startup_file"; then
        has_start=1
    fi

    if grep -Fqx -- "$end_marker" "$startup_file"; then
        has_end=1
    fi

    if (( ! has_start && ! has_end )); then
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
}
