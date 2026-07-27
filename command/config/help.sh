#!/usr/bin/env bash
set -euo pipefail

__basic_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg [command] [args...]

Commands:
  help [command]  Show basic help or details for a command.
  list            List available configuration modules.
  install         Install SysKit configuration files.
  uninstall       Remove installed SysKit configuration files.
  status          Show the status of installed configuration files.
EOF
}

__help_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg help [command]

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior.
EOF
}

__list_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg list

Options:
  No command-specific options.

Description:
  Lists each available configuration module using its canonical ID, name, and
  description from metadata.conf.
EOF
}

__install_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg install [args...]

Options:
  No command-specific options.

Description:
  Installs files from the SysKit configuration folder into their designated
  configuration locations.
EOF
}

__uninstall_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg uninstall [args...]

Options:
  No command-specific options.

Description:
  Removes SysKit configuration files from their designated locations.
EOF
}

__status_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg status [args...]

Options:
  No command-specific options.

Description:
  Shows the installation status of the managed configuration files.
EOF
}

main() {
    local help_type="${1:-basic}"

    case "$help_type" in
        basic | -h | --help)
            __basic_help
            ;;
        help)
            __help_help
            ;;
        list)
            __list_help
            ;;
        install)
            __install_help
            ;;
        uninstall)
            __uninstall_help
            ;;
        status)
            __status_help
            ;;
        *)
            printf 'Unknown configuration help topic: %s\n\n' "$help_type" >&2
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
