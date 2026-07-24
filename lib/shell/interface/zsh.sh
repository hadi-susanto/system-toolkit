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

    if [[ -f "$HOME/.local/share/syskit/zsh/module.d/$module.zsh" ]]; then
        return 0
    fi

    [[ -f "$HOME/.local/share/syskit/zsh/module.d/$module.sh" ]]
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
    local install_dir="$HOME/.local/share/syskit/zsh/module.d"

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

    if ! install -m 0644 -- "$source" "$install_dir/${source##*/}"; then
        log_error "Failed to install Zsh module: $module"

        return 1
    fi
}
