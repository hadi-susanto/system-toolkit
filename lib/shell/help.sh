#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$SHELL_LIB/__interface_loader.sh"

__basic_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh [command] [args...]

Commands:
  help [command]     Show basic help or details for a command.
  install <module>   Install [module] for ${display_name}.
  uninstall <module> Remove installed [module] from ${display_name}.
  activate           Activate ${display_name} module loader.
  deactivate         Deactivate ${display_name} module loader.
  status             Show whether the integration is installed and active.

Supported shells: Bash and Zsh.
EOF
}

__help_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh help [command]

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior.
EOF
}

__install_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh install [--force] <module...>
  syskit-${shell_name}.sh install [--force] --all

Options:
  -a, --all    Install every available shell module.
  -f, --force  Reinstall modules that are already installed.

Description:
  Installs one or more SysKit modules for ${display_name} into their designated
  location. Use --all instead of naming individual modules.
EOF
}

__uninstall_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh uninstall [--force] <module...>
  syskit-${shell_name}.sh uninstall [--force] --all

Options:
  -a, --all    Uninstall every available shell module.
  -f, --force  Force uninstall modules even its state is uninstalled.

Description:
  Unnstalls one or more SysKit modules for ${display_name} from their designated
  location. Use --all instead of naming individual modules.
EOF
}

__activate_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh activate [--force]

Options:
  -f, --force  Recreate an active loader and refresh its startup-file block.

Description:
  Creates the SysKit ${display_name} module loader and adds a managed source
  block to the shell startup file. Installed modules take effect in new shell
  sessions after activation.
EOF
}

__deactivate_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh deactivate [--force]

Options:
  -f, --force  Force removal even loader status is deactivated.

Description:
  Remove the SysKit ${display_name} module loader and remove the managed source
  block to the shell startup file. Installed modules will not removed, once
  re-activated all previous installed modules will be loaded automatically.
EOF
}

__status_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh status [args...]

Options:
  No command-specific options.

Description:
  Shows whether the SysKit ${display_name} integration is installed and active.
EOF
}

main() {
    local shell="${1:-}"
    local help_type="${2:-basic}"

    load_shell_interface \
        "$shell" "shell_display_name" || return 1

    if (( $# > 2 )); then
        log_error "The help command only accept zero or one argument"

        return 1
    fi

    case "$help_type" in
        basic | -h | --help)
            __basic_help "$shell" "$(shell_display_name)"
            ;;
        help)
            __help_help "$shell"
            ;;
        install)
            __install_help "$shell" "$(shell_display_name)"
            ;;
        uninstall)
            __uninstall_help "$shell" "$(shell_display_name)"
            ;;
        activate)
            __activate_help "$shell" "$(shell_display_name)"
            ;;
        deactivate)
            __deactivate_help "$shell" "$(shell_display_name)"
            ;;
        status)
            __status_help "$shell" "$(shell_display_name)"
            ;;
        *)
            log_error "Unknown shell help topic: $help_type"
            printf '\n' "$help_type" >&2
            __basic_help "$shell" "$(shell_display_name)" >&2

            return 1
            ;;
    esac
}

main "$@"
