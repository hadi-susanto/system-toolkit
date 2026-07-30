#!/usr/bin/env bash
set -euo pipefail

__basic_help() {
    cat <<'EOF'
System Toolkit Executable Integration
-------------------------------------

Usage:
  syskit-bin [command] [args...]

Commands:
  help [command]  Show basic help or details for a command.
  install         Install one or all SysKit executables.
  uninstall       Remove named SysKit executables.
  status          Show local and global installation status.

Scope:
  Install and uninstall use local scope by default. Global operations require
  elevated privileges.
EOF
}

__help_help() {
    cat <<'EOF'
System Toolkit Executable Integration
-------------------------------------

Usage:
  syskit-bin help [command]
  syskit-bin <command> help
  syskit-bin <command> -h
  syskit-bin <command> --help

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior. The post-command help forms are
  aliases for "help <command>".
EOF
}

__install_help() {
    cat <<'EOF'
System Toolkit Executable Integration
-------------------------------------

Usage:
  syskit-bin install [options] <name...>
  syskit-bin install [options] all

Options:
  -l, --local   Install into ~/.local/bin (default).
  -g, --global  Install into /usr/local/bin.
  -f, --force   Overwrite existing destination files.
  -a, --all     Install every available SysKit executable.

Description:
  Installs exact executable names from the SysKit bin directory with mode 0755.
  The positional name "all" is equivalent to --all. Existing destinations are
  skipped unless --force is given. Local installation warns when ~/.local/bin
  is not present in PATH but does not modify shell configuration.
EOF
}

__uninstall_help() {
    cat <<'EOF'
System Toolkit Executable Integration
-------------------------------------

Usage:
  syskit-bin uninstall [options] <name...>
  syskit-bin uninstall [options] --all

Options:
  -l, --local   Uninstall from ~/.local/bin (default).
  -g, --global  Uninstall from /usr/local/bin.
  -a, --all     Uninstall every available SysKit executable.

Description:
  Removes exact executable names from the selected installation directory.
  A checksum difference is assumed to mean that an update is available and
  does not prevent removal.
EOF
}

__status_help() {
    cat <<'EOF'
System Toolkit Executable Integration
-------------------------------------

Usage:
  syskit-bin status

Options:
  No command-specific options.

Description:
  Shows whether each installation directory is in PATH, then lists every
  available executable and its local and global installation state.
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
            printf 'Unknown executable help topic: %s\n\n' "$help_type" >&2
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
