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
  help [command]         Show basic help or details for a command.
  install <module...>    Install one or more modules for ${shell_name}.
  uninstall <module...>  Remove one or more installed modules from ${shell_name}.
  activate               Activate ${shell_name} module loader.
  deactivate             Deactivate ${shell_name} module loader.
  status [target]        Show the full report or one loader/module status.

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
  syskit-${shell_name} <command> help
  syskit-${shell_name} <command> -h
  syskit-${shell_name} <command> --help

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior. The post-command help forms are
  aliases for "help <command>".
EOF
}

__install_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} install [--force] <module...>
  syskit-${shell_name} install [--force] --all

Options:
  -a, --all    Install every available shell module.
  -f, --force  Reinstall modules and bypass failed dependency checks.

Description:
  Installs one or more SysKit modules for ${shell_name} into their designated
  location. A unique module-name segment or canonical <category/module> ID is
  accepted. Before installation, a module-specific dependency check is run when
  available; otherwise, the module-name segment is checked as a command. Use
  --all instead of naming individual modules.
EOF
}

__uninstall_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} uninstall [--force] <module...>
  syskit-${shell_name} uninstall [--force] --all

Options:
  -a, --all    Uninstall every available shell module.
  -f, --force  Attempt removal even when a module is not installed.

Description:
  Uninstalls one or more SysKit modules for ${shell_name} from their designated
  location. A unique module-name segment or canonical <category/module> ID is
  accepted. Use --all instead of naming individual modules.
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
  -f, --force  Attempt removal even when the loader is inactive.

Description:
  Removes the SysKit ${shell_name} module loader and its managed source block
  from the shell startup file. Installed modules are preserved and will be
  loaded automatically if the loader is activated again.
EOF
}

__status_help() {
    local shell_name="$1"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name} status [all]
  syskit-${shell_name} status loader
  syskit-${shell_name} status <category/module>

Options:
  No command-specific options.

Description:
  With no target or with "all", shows the complete ${shell_name} module and
  loader report.
  The "loader" target reports whether the shell exists and its loader is
  active. A canonical module ID reports whether that module is installed.
EOF
}

main() {
    local shell="${1:-}"
    local help_type="${2:-basic}"

    if (( $# > 2 )); then
        log_error "The help command accepts zero or one argument"

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
