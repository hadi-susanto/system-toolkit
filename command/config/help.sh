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
  install         Install one configuration module.
  uninstall       Safely uninstall one configuration module.
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

__install_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg install [--force] <category/module>

Options:
  -f, --force  Override supported module skips and existing-target safeguards.

Description:
  Validates and installs exactly one configuration module. The module owns all
  interactive decisions and target handling. Supporting modules may also
  require force to overwrite managed targets. Force does not bypass a blocked
  check or automatically approve module prompts.
EOF
}

__uninstall_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg uninstall [--force] <category/module>

Options:
  -f, --force  Override supported module skips and checksum safeguards.

Description:
  Safely uninstalls exactly one configuration module when it provides
  uninstall.sh. When check_uninstall_requirements.sh is present, it runs before
  uninstallation. Supporting modules may also require force to remove modified
  managed files. Force does not bypass a blocked safety check or automatically
  approve module prompts.
EOF
}

__status_help() {
    cat <<'EOF'
System Toolkit Configuration Integration
----------------------------------------

Usage:
  syskit-cfg status <category/module>
  syskit-cfg status all

Options:
  -a, --all  Show status for every available configuration module.

Description:
  Shows custom status output for one configuration module. The positional
  value "all" is equivalent to --all. When no module is given, shows this help.
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
