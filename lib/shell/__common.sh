## deprecated will be removed when no one reference it, rename to __modules.sh
# shell_display_name <shell>
#
# Formats a supported shell name for user-facing output.
#
# Parameters:
#   shell    Lowercase shell identifier.
#
# Output:
#   Prints the display name for the shell.
#
# Returns:
#   1 when the shell is unsupported.
#
shell_display_name() {
    case "$1" in
        bash)
            printf 'Bash\n'
            ;;
        zsh)
            printf 'Zsh\n'
            ;;
        *)
            log_error "Unsupported shell: $1"

            return 1
            ;;
    esac
}
