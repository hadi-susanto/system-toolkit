##
# parse_bin_scope <options_name> <args_name> [arguments...]
#
# Resolves local or global binary scope and preserves positional arguments.
#
# Parameters:
#   options_name    Name of the associative array that receives scope state.
#   args_name       Name of the indexed array that receives other arguments.
#   arguments       Command arguments to parse.
#
# Returns:
#   1 when a scope option is unknown or conflicts with an earlier scope.
#
parse_bin_scope() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"
    local scope_was_set="false"

    options_ref=(
        [SCOPE]="local"
    )
    args_ref=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l | --local)
                if [[ "$scope_was_set" == "true" ]] &&
                    [[ "${options_ref[SCOPE]}" != "local" ]]; then
                    log_error "Cannot combine local and global scope options"

                    return 1
                fi

                options_ref[SCOPE]="local"
                scope_was_set="true"
                ;;
            -g | --global)
                if [[ "$scope_was_set" == "true" ]] &&
                    [[ "${options_ref[SCOPE]}" != "global" ]]; then
                    log_error "Cannot combine local and global scope options"

                    return 1
                fi

                options_ref[SCOPE]="global"
                scope_was_set="true"
                ;;
            --)
                shift
                args_ref+=("$@")

                return 0
                ;;
            -*)
                log_error "Unknown scope option: $1"

                return 1
                ;;
            *)
                args_ref+=("$1")
                ;;
        esac

        shift
    done
}
