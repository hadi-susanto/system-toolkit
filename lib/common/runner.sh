if (( ${__SYSKIT_RUNNER_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_RUNNER_LOADED=1

source "$COMMON_LIB/common.sh"

##
# run_syskit_bin <executable> [arguments...]
#
# Runs a SysKit-owned executable from SYSKIT_ROOT through Bash.
#
# Parameters:
#   executable    Executable filename in the syskit-<name> format.
#   arguments     Arguments passed unchanged to the executable.
#
# Output:
#   Preserves the executable's stdout and stderr.
#
# Returns:
#   2 when the executable name is missing or invalid.
#   127 when SYSKIT_ROOT is unset or the executable is unavailable.
#   Otherwise, preserves the executable's exit status.
#
run_syskit_bin() {
    if (( $# == 0 )); then
        log_error "A SysKit executable name is required"

        return 2
    fi

    local executable="$1"
    local root="${SYSKIT_ROOT:-}"
    local executable_path
    shift

    if [[ ! "$executable" =~ ^syskit-[a-z0-9][a-z0-9-]*$ ]]; then
        log_error "Invalid SysKit executable name: $executable"

        return 2
    fi

    if [[ -z "$root" ]]; then
        log_error "SYSKIT_ROOT is not set"

        return 127
    fi

    executable_path="$root/$executable"

    if [[ ! -f "$executable_path" ]]; then
        log_error "SysKit executable is unavailable: $executable_path"

        return 127
    fi

    bash "$executable_path" "$@"
}

##
# install_shell_integration <shell> <canonical_id> <force>
#
# Installs a configuration module's integration for a shell.
#
# Parameters:
#   shell           Shell identifier used by the SysKit executable.
#   canonical_id    Shell module ID in <category>/<module> format.
#   force           1 to force installation, or 0 for normal installation.
#
# Returns:
#   1 when installation fails.
#
install_shell_integration() {
    local shell="$1"
    local canonical_id="$2"
    local force="$3"
    local -a args=(install "$canonical_id")

    if (( force )); then
        args+=(--force)
    fi

    if ! run_syskit_bin "syskit-$shell" "${args[@]}"; then
        log_error "Failed to install $shell shell integration: $canonical_id"

        return 1
    fi
}

##
# install_shell_loader <shell> <force>
#
# Activates a SysKit shell loader.
#
# Parameters:
#   shell    Shell identifier used by the SysKit executable.
#   force    1 to force activation, or 0 for normal activation.
#
# Returns:
#   1 when activation fails.
#
install_shell_loader() {
    local shell="$1"
    local force="$2"
    local -a args=(activate)

    if (( force )); then
        args+=(--force)
    fi

    if ! run_syskit_bin "syskit-$shell" "${args[@]}"; then
        log_error "Failed to install the SysKit $shell loader"

        return 1
    fi
}

##
# run_shell_status <shell> <selector>
#
# Queries a shell loader or module status without emitting command output.
#
# Parameters:
#   shell       Shell identifier used by the SysKit executable.
#   selector    The loader keyword or canonical shell module ID.
#
# Returns:
#   Preserves the shell status command's exit status.
#
run_shell_status() {
    local shell="$1"
    local selector="$2"

    run_syskit_bin "syskit-$shell" status "$selector" >/dev/null 2>&1
}

##
# print_loader_status <shell>
#
# Prints the current SysKit loader status for a shell.
#
# Parameters:
#   shell    Shell identifier used by the SysKit executable.
#
# Output:
#   Prints a colorized loader status to stdout.
#
# Returns:
#   1 when the loader status cannot be determined.
#
print_loader_status() {
    local shell="$1"
    local status=0

    if run_shell_status "$shell" loader; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            printf '%s[✓] active%s\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[✗] inactive%s\n' "$COLOR_RED" "$COLOR_RESET"
            ;;
        2)
            printf '%s[⚠] shell not installed%s\n' "$COLOR_YELLOW" "$COLOR_RESET"
            ;;
        *)
            log_error "Unable to determine $shell loader status"
            printf '%s[?] unknown]\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
    esac
}

##
# print_module_status <shell> <canonical_id>
#
# Prints the installation status of a module for a shell.
#
# Parameters:
#   shell           Shell identifier used by the SysKit executable.
#   canonical_id    Shell module ID in <category>/<module> format.
#
# Output:
#   Prints a colorized module status to stdout.
#
# Returns:
#   1 when the module status cannot be determined.
#
print_module_status() {
    local shell="$1"
    local canonical_id="$2"
    local status=0

    if run_shell_status "$shell" "$canonical_id"; then
        status=0
    else
        status=$?
    fi

    case "$status" in
        0)
            printf '%s[✓] installed%s\n' "$COLOR_GREEN" "$COLOR_RESET"
            ;;
        1)
            printf '%s[✗] not installed%s\n' "$COLOR_RED" "$COLOR_RESET"
            ;;
        *)
            log_error "Unable to determine $shell module status: $canonical_id"
            printf '%s[?] unknown%s\n' "$COLOR_YELLOW" "$COLOR_RESET"

            return 1
            ;;
    esac
}

##
# uninstall_shell_integration <shell> <canonical_id> <force>
#
# Uninstalls a configuration module's integration for a shell.
#
# Parameters:
#   shell           Shell identifier used by the SysKit executable.
#   canonical_id    Shell module ID in <category>/<module> format.
#   force           1 to force uninstallation, or 0 for normal uninstallation.
#
# Returns:
#   1 when uninstallation fails.
#
uninstall_shell_integration() {
    local shell="$1"
    local canonical_id="$2"
    local force="$3"
    local -a args=(uninstall "$canonical_id")

    if (( force )); then
        args+=(--force)
    fi

    if ! run_syskit_bin "syskit-$shell" "${args[@]}"; then
        log_error "Failed to uninstall $shell shell integration: $canonical_id"

        return 1
    fi
}

##
# uninstall_shell_loader <shell> <force>
#
# Deactivates a SysKit shell loader.
#
# Parameters:
#   shell    Shell identifier used by the SysKit executable.
#   force    1 to force deactivation, or 0 for normal deactivation.
#
# Returns:
#   1 when deactivation fails.
#
uninstall_shell_loader() {
    local shell="$1"
    local force="$2"
    local -a args=(deactivate)

    if (( force )); then
        args+=(--force)
    fi

    if ! run_syskit_bin "syskit-$shell" "${args[@]}"; then
        log_error "Failed to uninstall the SysKit $shell loader"

        return 1
    fi
}
