#!/usr/bin/env bash
set -euo pipefail

__basic_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh [command] [args...]

Commands:
  help [command]  Show basic help or details for a command.
  install         Install the ${display_name} integration.
  uninstall       Remove the installed ${display_name} integration.
  enable          Enable the installed ${display_name} integration.
  disable         Disable the ${display_name} integration without removing it.
  status          Show whether the integration is installed and enabled.

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
  syskit-${shell_name}.sh install [args...]

Options:
  No command-specific options.

Description:
  Installs the SysKit ${display_name} integration into its designated location.
  Run the enable command afterward to make the integration take effect.
EOF
}

__uninstall_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh uninstall [args...]

Options:
  No command-specific options.

Description:
  Removes the installed SysKit ${display_name} integration from its designated
  location.
EOF
}

__enable_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh enable [args...]

Options:
  No command-specific options.

Description:
  Enables the installed SysKit ${display_name} integration. Installing the
  integration alone has no effect until it is enabled.
EOF
}

__disable_help() {
    local shell_name="$1"
    local display_name="$2"

    cat <<EOF
System Toolkit Shell Integration (Shell-Dependent)
--------------------------------------------------

Usage:
  syskit-${shell_name}.sh disable [args...]

Options:
  No command-specific options.

Description:
  Disables the SysKit ${display_name} integration without removing its files.
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
  Shows whether the SysKit ${display_name} integration is installed and enabled.
EOF
}

main() {
    local shell_name="${1:-shell}"
    local help_type="${2:-basic}"
    local display_name="Shell"

    case "$shell_name" in
        bash)
            display_name="Bash"
            ;;
        zsh)
            display_name="Zsh"
            ;;
    esac

    case "$help_type" in
        basic | -h | --help)
            __basic_help "$shell_name" "$display_name"
            ;;
        help)
            __help_help "$shell_name"
            ;;
        install)
            __install_help "$shell_name" "$display_name"
            ;;
        uninstall)
            __uninstall_help "$shell_name" "$display_name"
            ;;
        enable)
            __enable_help "$shell_name" "$display_name"
            ;;
        disable)
            __disable_help "$shell_name" "$display_name"
            ;;
        status)
            __status_help "$shell_name" "$display_name"
            ;;
        *)
            printf 'Unknown shell help topic: %s\n\n' "$help_type" >&2
            __basic_help "$shell_name" "$display_name" >&2

            return 1
            ;;
    esac
}

main "$@"
