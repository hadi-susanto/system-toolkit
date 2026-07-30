if (( ${__SYSKIT_PROMPT_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_PROMPT_LOADED=1

__prompt_terminal_available() {
    [[ -r /dev/tty && -w /dev/tty ]]
}

__prompt_write() {
    local format="$1"
    shift

    # The format string is supplied only by private prompt helpers.
    # shellcheck disable=SC2059
    printf "$format" "$@" >/dev/tty
}

__prompt_read() {
    local variable_name="$1"

    IFS= read -r "$variable_name" </dev/tty
}

__prompt_cursor_up() {
    local lines="${1:-1}"

    __prompt_write '\033[%dA' "$lines"
}

__prompt_clear_line() {
    __prompt_write '\033[2K\r'
}

__print_input_error() {
    __prompt_write '%b%s%b\n' \
        "${COLOR_RED-$'\033[0;31m'}" \
        "$*" \
        "${COLOR_RESET-$'\033[0m'}"
}

##
# show_temporary_input_error <message>
#
# Displays an input error while repositioning the cursor so the input prompt
# can be written again.
#
# Parameters:
#   message    Single-line error message to display.
#
show_temporary_input_error() {
    local message="$1"

    __print_input_error "$message"
    __prompt_cursor_up 2
    __prompt_clear_line
}

__write_choose_option_question() {
    local question="$1"
    shift

    local option
    local index=1

    __prompt_write '%s\n' "$question"

    for option in "$@"; do
        __prompt_write '  %d. %s\n' "$index" "$option"
        ((index += 1))
    done

    __prompt_write '\n  X. Finish\n\n'
}

__read_option() {
    local option_count="$1"
    local selected
    local selected_number

    while true; do
        __prompt_write 'Choose an option [1-%d/X]: ' "$option_count"

        if ! __prompt_read selected; then
            printf '\nUnable to read user input.\n' >&2

            return 1
        fi

        case "$selected" in
            [Xx])
                printf 'X\n'

                return 0
                ;;
        esac

        if [[ "$selected" =~ ^[0-9]{1,9}$ ]]; then
            selected_number=$((10#$selected))

            if (( selected_number >= 1 && selected_number <= option_count )); then
                printf '%d\n' "$selected_number"

                return 0
            fi
        fi

        show_temporary_input_error \
            "Invalid choice. Enter a number between 1 and $option_count, or X to finish."
    done
}

##
# choose_option <question> <option...>
#
# Prompts for one numbered option or X to finish.
#
# Parameters:
#   question    Heading displayed before the options.
#   option      One or more selectable option labels.
#
# Output:
#   Prints the selected one-based option number, or X when finished.
#
# Returns:
#   1 when arguments are invalid, no terminal is available, or input fails.
#
choose_option() {
    if (( $# < 2 )); then
        printf 'choose_option requires a question and at least one option.\n' >&2

        return 1
    fi

    if ! __prompt_terminal_available; then
        printf 'choose_option requires an interactive terminal.\n' >&2

        return 1
    fi

    local question="$1"
    shift

    local -a options=("$@")

    __write_choose_option_question "$question" "${options[@]}"
    __read_option "${#options[@]}"
}

##
# confirm_action <question>
#
# Prompts for an explicit yes or no answer. An empty answer defaults to no.
#
# Parameters:
#   question    Confirmation question to display.
#
# Returns:
#   0 for y or yes.
#   1 for an empty answer, n, or no.
#   2 when no terminal is available or input fails.
#
confirm_action() {
    if (( $# != 1 )); then
        printf 'confirm_action requires exactly one question.\n' >&2

        return 2
    fi

    if ! __prompt_terminal_available; then
        printf 'confirm_action requires an interactive terminal.\n' >&2

        return 2
    fi

    local question="$1"
    local answer

    while true; do
        __prompt_write '%s [y/N]: ' "$question"

        if ! __prompt_read answer; then
            printf '\nUnable to read user input.\n' >&2

            return 2
        fi

        case "$answer" in
            [Yy] | [Yy][Ee][Ss])
                return 0
                ;;
            '' | [Nn] | [Nn][Oo])
                return 1
                ;;
            *)
                show_temporary_input_error \
                    'Invalid confirmation. Enter Y or N.'
                ;;
        esac
    done
}
