readonly ZSH_BASE_DIR="$HOME/.local/share/syskit/zsh"

##
# support_module <module>
#
# Checks whether a module provides a Zsh-specific or generic source file.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   1 when no compatible source file exists.
#
support_module() {
    local module="$1"

    if [[ -f "$SHELL_DIR/$module/$module.zsh" ]]; then
        return 0
    fi

    [[ -f "$SHELL_DIR/$module/$module.sh" ]]
}

##
# module_installed <module>
#
# Checks whether a Zsh-compatible module is installed.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   1 when neither a Zsh-specific nor generic installed file exists.
#
module_installed() {
    local module="$1"

    if [[ -f "$ZSH_BASE_DIR/module.d/$module.zsh" ]]; then
        return 0
    fi

    [[ -f "$ZSH_BASE_DIR/module.d/$module.sh" ]]
}

##
# install_module <module>
#
# Installs the preferred Zsh-compatible source for a module.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   1 when no compatible source exists or the file cannot be installed.
#
install_module() {
    local module="$1"
    local source="$SHELL_DIR/$module/$module.zsh"
    local install_dir="$ZSH_BASE_DIR/module.d"
    local target="$install_dir/$module.zsh"

    if [[ ! -f "$source" ]]; then
        source="$SHELL_DIR/$module/$module.sh"
    fi

    if [[ ! -f "$source" ]]; then
        log_error "No Zsh-compatible source is available for module: $module"

        return 1
    fi

    if ! install -d -m 0755 -- "$install_dir"; then
        log_error "Failed to create Zsh module directory: $install_dir"

        return 1
    fi

    if ! install -m 0644 -- "$source" "$target"; then
        log_error "Failed to install Zsh module: $module"

        return 1
    fi
}

##
# installed_module_path <module>
#
# Returns the path to the installed Zsh module source file.
# This function behaves similarly to `installed_module`, except
# that it prints the resolved module path instead of returning
# only an exit status.
#
# Parameters:
#   module    Module name.
#
# Output:
#   Full path to the installed Zsh module source file.
#
# Returns:
#   1 when the module is not installed.
#
installed_module_path() {
    local module="$1"
    local path="$ZSH_BASE_DIR/module.d/$module.zsh"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    path="$ZSH_BASE_DIR/module.d/$module.sh"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    return 1
}

##
# module_source_path <module>
#
# Returns the preferred compatible source file for a shell module.
# A shell-specific source file is preferred over the generic source file.
#
# Parameters:
#   module    Shell module name.
#
# Output:
#   Full path to the preferred compatible source file.
#
# Returns:
#   1 when no compatible source file exists.
#
module_source_path() {
    local module="$1"
    local path="$SHELL_DIR/$module/$module.zsh"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    path="$SHELL_DIR/$module/$module.sh"

    if [[ -f "$path" ]]; then
        printf '%s\n' "$path"

        return 0
    fi

    return 1
}

##
# uninstall_module <module>
#
# Removes every installed Zsh-compatible file for a module.
#
# Parameters:
#   module    Shell module name.
#
# Returns:
#   A non-zero status when an installed file cannot be removed.
#
uninstall_module() {
    local module="$1"
    local module_dir="$ZSH_BASE_DIR/module.d"
    local extension
    local file
    local failed=0

    for extension in zsh sh; do
        file="$module_dir/$module.$extension"

        if [[ ! -e "$file" ]] && [[ ! -L "$file" ]]; then
            continue
        fi

        if ! rm -f -- "$file"; then
            log_error "Failed to remove Zsh module file: $file"
            failed=1
        fi
    done

    return "$failed"
}

##
# loader_active
#
# Checks whether the Zsh loader file and its shell startup marker exist.
#
# Returns:
#   1 when the loader, ~/.zshrc, or both managed markers are absent.
#
loader_active() {
    local loader="$ZSH_BASE_DIR/loader.sh"
    local startup_file="$HOME/.zshrc"
    local start_marker="# >>> syskit zsh loader >>>"
    local end_marker="# <<< syskit zsh loader <<<"

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

    log_warn "Zsh loader markers are inconsistent; manual cleanup may be required"

    return 0
}

##
# activate_loader
#
# Creates the Zsh module loader and adds its managed block to ~/.zshrc.
#
# Returns:
#   1 when the loader or startup file cannot be written, or when an incomplete
#   managed block prevents a safe update.
#
activate_loader() {
    local loader="$ZSH_BASE_DIR/loader.sh"
    local startup_file="$HOME/.zshrc"
    local start_marker="# >>> syskit zsh loader >>>"
    local end_marker="# <<< syskit zsh loader <<<"
    local loader_tmp
    local startup_tmp
    local last_byte
    local has_start=0
    local has_end=0

    if [[ -L "$startup_file" ]]; then
        if ! startup_file="$(readlink -f -- "$startup_file")"; then
            log_error "Failed to resolve Zsh startup symlink: $HOME/.zshrc"

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
        log_error "Cannot safely replace an incomplete SysKit Zsh loader block: $startup_file"

        return 1
    fi

    if ! install -d -m 0755 -- "$ZSH_BASE_DIR"; then
        log_error "Failed to create Zsh loader directory: $ZSH_BASE_DIR"

        return 1
    fi

    if ! loader_tmp="$(mktemp "$loader.XXXXXX")"; then
        log_error "Failed to create a temporary Zsh loader"

        return 1
    fi

    if ! cat >"$loader_tmp" <<'EOF'
for __syskit_module_file in "$HOME"/.local/share/syskit/zsh/module.d/*(N); do
    if [[ ! -f "$__syskit_module_file" ]]; then
        continue
    fi

    case "$__syskit_module_file" in
        *.zsh | *.sh)
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
        log_error "Failed to write the temporary Zsh loader"
        rm -f -- "$loader_tmp"

        return 1
    fi

    if ! chmod 0644 -- "$loader_tmp"; then
        log_error "Failed to set Zsh loader permissions: $loader_tmp"
        rm -f -- "$loader_tmp"

        return 1
    fi

    if ! mv -f -- "$loader_tmp" "$loader"; then
        log_error "Failed to install Zsh loader: $loader"
        rm -f -- "$loader_tmp"

        return 1
    fi

    if [[ ! -e "$startup_file" ]] && ! install -m 0644 -- /dev/null "$startup_file"; then
        log_error "Failed to create Zsh startup file: $startup_file"

        return 1
    fi

    if [[ ! -f "$startup_file" ]]; then
        log_error "Zsh startup path is not a regular file: $startup_file"

        return 1
    fi

    if ! startup_tmp="$(mktemp "$startup_file.XXXXXX")"; then
        log_error "Failed to create a temporary Zsh startup file"

        return 1
    fi

    if (( has_start )); then
        # in this line both has_start and has_end is true.
        if ! awk -v start="$start_marker" -v end="$end_marker" '
            $0 == start { managed = 1; next }
            managed && $0 == end { managed = 0; next }
            !managed { print }
        ' "$startup_file" >"$startup_tmp"; then
            log_error "Failed to remove the existing SysKit Zsh loader block"
            rm -f -- "$startup_tmp"

            return 1
        fi
    elif ! cat -- "$startup_file" >"$startup_tmp"; then
        log_error "Failed to copy Zsh startup file: $startup_file"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if [[ -s "$startup_tmp" ]]; then
        if ! last_byte="$(tail -c 1 -- "$startup_tmp")"; then
            log_error "Failed to inspect the temporary Zsh startup file"
            rm -f -- "$startup_tmp"

            return 1
        fi

        if [[ -n "$last_byte" ]] && ! printf '\n' >>"$startup_tmp"; then
            log_error "Failed to terminate the existing Zsh startup content"
            rm -f -- "$startup_tmp"

            return 1
        fi
    fi

    if ! printf '%s\n' \
        "$start_marker" \
        "# Do not delete either SysKit loader marker. Add custom code after the end marker." \
        '__syskit_loader="$HOME/.local/share/syskit/zsh/loader.sh"' \
        'if [[ -f "$__syskit_loader" ]]; then' \
        '    source "$__syskit_loader"' \
        'else' \
        '    printf "%s\n" "SysKit inconsistency detected: loader activation exists in .zshrc, but the loader file is missing. Manual cleanup may be required." >&2' \
        'fi' \
        'unset __syskit_loader' \
        "$end_marker" >>"$startup_tmp"; then
        log_error "Failed to append the SysKit Zsh loader block"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! chmod --reference="$startup_file" "$startup_tmp"; then
        log_error "Failed to preserve Zsh startup file permissions"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! mv -f -- "$startup_tmp" "$startup_file"; then
        log_error "Failed to update Zsh startup file: $startup_file"
        rm -f -- "$startup_tmp"

        return 1
    fi
}

##
# deactivate_loader
#
# Removes the Zsh loader and, when both markers exist, atomically removes its
# managed block from ~/.zshrc.
#
# Returns:
#   1 when cleanup fails or only one managed marker exists.
#
deactivate_loader() {
    local loader="$HOME/.local/share/syskit/zsh/loader.sh"
    local startup_file="$HOME/.zshrc"
    local start_marker="# >>> syskit zsh loader >>>"
    local end_marker="# <<< syskit zsh loader <<<"
    local startup_tmp
    local has_start=0
    local has_end=0

    if [[ -L "$startup_file" ]]; then
        if ! startup_file="$(readlink -f -- "$startup_file")"; then
            log_error "Failed to resolve Zsh startup symlink: $HOME/.zshrc"

            return 1
        fi
    fi

    if [[ ! -f "$startup_file" ]]; then
        if [[ -f "$loader" ]] && ! rm -f -- "$loader"; then
            log_warn ".zshrc does not load the SysKit loader, but the loader file could not be removed."
            log_warn "The leftover file will not affect Zsh and can be safely ignored."
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
            log_warn ".zshrc does not load the SysKit loader, but the loader file could not be removed."
            log_warn "The leftover file will not affect Zsh and can be safely ignored."
        fi

        return 0
    fi

    if (( has_start != has_end )); then
        log_error "Cannot safely remove an incomplete SysKit Zsh loader block: $startup_file"

        return 1
    fi

    if ! startup_tmp="$(mktemp "$startup_file.XXXXXX")"; then
        log_error "Failed to create a temporary Zsh startup file"

        return 1
    fi

    if ! awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { managed = 1; next }
        managed && $0 == end { managed = 0; next }
        !managed { print }
    ' "$startup_file" >"$startup_tmp"; then
        log_error "Failed to remove the SysKit Zsh loader block"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! chmod --reference="$startup_file" "$startup_tmp"; then
        log_error "Failed to preserve Zsh startup file permissions"
        rm -f -- "$startup_tmp"

        return 1
    fi

    if ! mv -f -- "$startup_tmp" "$startup_file"; then
        log_error "Failed to update Zsh startup file: $startup_file"
        rm -f -- "$startup_tmp"

        return 1
    fi

    # Ignore missing loader files so this function is idempotent.
    if [[ -f "$loader" ]] && ! rm -f -- "$loader"; then
        log_error "Failed to remove Zsh loader: $loader"

        return 1
    fi

    return 0
}
