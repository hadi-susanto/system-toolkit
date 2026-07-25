readonly SHELL_INTERFACE_LIB="${SHELL_LIB}/interface"

##
# exists_shell_interface <shell>
#
# Checks whether a shell has an interface implementation.
#
# Parameters:
#   shell    Shell identifier.
#
# Returns:
#   1 when the identifier is unsafe or its interface file does not exist.
#
exists_shell_interface() {
    local shell="$1"

    if [[ -z "$shell" ]] || [[ "$shell" == -* ]] || [[ "$shell" == */* ]]; then
        return 1
    fi

    [[ -f "$SHELL_INTERFACE_LIB/$shell.sh" ]]
}

##
# load_shell_interface <shell> [function_names...]
#
# Loads a shell interface and verifies its required function contracts.
#
# Parameters:
#   shell             Shell identifier.
#   function_names    Function contracts required by the caller.
#
# Returns:
#   1 when the interface cannot be loaded or a contract is missing.
#
load_shell_interface() {
    local shell="$1"
    shift

    local interface="$SHELL_INTERFACE_LIB/$shell.sh"
    local function_name

    if ! exists_shell_interface "$shell"; then
        log_error "Unsupported shell interface: ${shell:-<missing>}"

        return 1
    fi

    if ! source "$interface"; then
        log_error "Failed to load shell interface: $shell"

        return 1
    fi

    for function_name in "$@"; do
        if declare -F "$function_name" >/dev/null; then
            continue
        fi

        log_error "Shell interface '$shell' does not implement: $function_name"

        return 1
    done
}

##
# current_user_shell
#
# Returns the user's configured login shell.
# The returned value is the full path to the shell
# as configured in the user account database.
#
# Output:
#   Full path to the user's configured login shell.
#
current_user_shell() {
    printf '%s\n' "$(getent passwd "$USER" | cut -d: -f7)"
}
