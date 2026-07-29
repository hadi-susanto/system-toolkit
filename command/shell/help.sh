#!/usr/bin/env bash
set -euo pipefail

__basic_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} [command] [args...]

Commands:
  help [command]     Show basic help or details for a command.
  install <id>       Install a module for ${shell_name}.
                     <id> in canonical format: <category/module>.
  uninstall <id>     Remove an installed module from ${shell_name}.
                     <id> in canonical format: <category/module>.
  activate           Activate ${shell_name} module loader.
  deactivate         Deactivate ${shell_name} module loader.
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
  syskit-${shell_name} help [command]

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior.
EOF
}

__install_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} install [--force] <category/module...>
  syskit-${shell_name} install [--force] --all

Options:
  -a, --all    Install every available shell module.
  -f, --force  Reinstall modules and bypass failed dependency checks.

Description:
  Installs one or more SysKit modules for ${shell_name} into their designated
  location. Module IDs use the <category>/<module> format. Before installation,
  a module-specific dependency check is run when available; otherwise, the
  module-name segment is checked as a command. Use --all instead of naming
  individual modules.
EOF
}

__uninstall_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} uninstall [--force] <category/module...>
  syskit-${shell_name} uninstall [--force] --all

Options:
  -a, --all    Uninstall every available shell module.
  -f, --force  Force uninstall modules even its state is uninstalled.

Description:
  Unnstalls one or more SysKit modules for ${shell_name} from their designated
  location. Use --all instead of naming individual modules.
EOF
}

__activate_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} activate [--force]

Options:
  -f, --force  Recreate an active loader and refresh its startup-file block.

Description:
  Creates the SysKit ${shell_name} module loader and adds a managed source
  block to the shell startup file. Installed modules take effect in new shell
  sessions after activation.
EOF
}

__deactivate_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} deactivate [--force]

Options:
  -f, --force  Force removal even loader status is deactivated.

Description:
  Remove the SysKit ${shell_name} module loader and remove the managed source
  block to the shell startup file. Installed modules will not removed, once
  re-activated all previous installed modules will be loaded automatically.
EOF
}

__status_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} status [args...]

Options:
  No command-specific options.

Description:
  Shows whether the SysKit ${shell_name} integration is installed and active.
EOF
}

main() {
    local shell="${1:-}"
    local help_type="${2:-basic}"

    if (( $# > 2 )); then
        log_error "The help command only accept zero or one argument"

        return 1
    fi

    case "$help_type" in
        basic | -h | --help)
            __basic_help "$shell"
            ;;
        help)
            __help_help "$shell"
            ;;
        install)
            __install_help "$shell"
            ;;
        uninstall)
            __uninstall_help "$shell"
            ;;
        activate)
            __activate_help "$shell"
            ;;
        deactivate)
            __deactivate_help "$shell"
            ;;
        status)
            __status_help "$shell"
            ;;
        *)
            printf 'Unknown executable help topic: %s\n\n' "$help_type" >&2
            __basic_help "$shell" >&2

            return 1
            ;;
    esac
}

main "$@"
