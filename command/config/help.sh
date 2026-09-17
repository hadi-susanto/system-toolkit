#!/usr/bin/env bash
set -euo pipefail

__basic_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg <command> [args...]
  syskit-cfg <module>

Commands:
  help [command]  Show basic help or details for a command.
  list            List available configuration modules.
  configure       Configure one configuration module.
  status          Show configuration module status.
EOF
}

__help_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg help [command]
  syskit-cfg <command> help
  syskit-cfg <command> -h
  syskit-cfg <command> --help

Arguments:
  command  Optional command for which detailed help should be displayed.

Description:
  Shows basic toolkit help when no command is given. When a command is given,
  shows its usage, options, and behavior. The post-command help forms are
  aliases for "help <command>".
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

__configure_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg configure <module>
  syskit-cfg <module>

Options:
  -f, --force  Force configuration when supported by the module

Description:
  Configures exactly one module by directly running its main.sh. A unique
  module-name segment or canonical <category/module> ID is accepted.
EOF
}

__status_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg status <module...>
  syskit-cfg status --all

Options:
  -a, --all  Show status for every available configuration module.

Description:
  Shows custom status output for one or more configuration modules.
  Each module may be specified using its unique name or canonical ID.
  The positional value "all" is equivalent to --all.
  When no module is given, shows this help.
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
        configure)
            __configure_help
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
