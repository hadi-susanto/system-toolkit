#!/usr/bin/env bash
set -euo pipefail

__basic_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh [command] [args...]

Commands:
  help [command]  Show basic help or details for a command.
  install         Install SysKit binaries in a designated location.
  uninstall       Remove installed SysKit binaries.
  enable          Enable an installed binary integration.
  disable         Disable the binary integration without removing it.
  status          Show whether the binary integration is installed and enabled.

Scope:
  Install, uninstall, enable, and disable use local scope by default. Run
  command-specific help to see the available scope options.
EOF
}

__help_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh help [command]

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior.
EOF
}

__install_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh install [args...]

Options:
  -l, --local   Install for the current user (default).
  -g, --global  Install system-wide.

Description:
  Installs binaries from the SysKit binaries folder into the designated
  directory for the current user or system-wide, based on the selected scope.
  Run the enable command afterward to make the integration take effect.
EOF
}

__uninstall_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh uninstall [args...]

Options:
  -l, --local   Uninstall for the current user (default).
  -g, --global  Uninstall system-wide.

Description:
  Removes installed SysKit binaries from the designated location for the
  selected scope.
EOF
}

__enable_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh enable [args...]

Options:
  -l, --local   Enable the current user's integration (default).
  -g, --global  Enable the system-wide integration.

Description:
  Enables the installed binary integration for the selected scope. Installing
  the integration alone has no effect until it is enabled.
EOF
}

__disable_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh disable [args...]

Options:
  -l, --local   Disable the current user's integration (default).
  -g, --global  Disable the system-wide integration.

Description:
  Disables the binary integration for the selected scope without removing the
  installed binaries.
EOF
}

__status_help() {
    cat <<'EOF'
System Toolkit Binary Integration
---------------------------------

Usage:
  syskit-bin.sh status [args...]

Options:
  No command-specific options.

Description:
  Shows whether the binary integration is installed and enabled.
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
        enable)
            __enable_help
            ;;
        disable)
            __disable_help
            ;;
        status)
            __status_help
            ;;
        *)
            printf 'Unknown binary help topic: %s\n\n' "$help_type" >&2
            __basic_help >&2

            return 1
            ;;
    esac
}

main "$@"
