# Private whiptail backend for prompt.sh. Sourced only by prompt.sh, which owns
# the load-once guard. Public functions mirror __prompt-basic.sh.

# Forced theme so the dialogs stay blue on systems with another default palette.
__prompt_whiptail_colors='root=white,blue
roottext=white,blue
shadow=,black
window=black,lightgray
border=black,lightgray
title=blue,lightgray
label=black,lightgray
textbox=black,lightgray
acttextbox=black,lightgray
listbox=black,lightgray
actlistbox=white,blue
sellistbox=black,lightgray
actsellistbox=white,blue
checkbox=black,lightgray
actcheckbox=white,blue
entry=black,cyan
disentry=gray,lightgray
button=black,cyan
actbutton=white,blue
compactbutton=black,lightgray
helpline=white,blue
emptyscale=,lightgray
fullscale=,blue'

__prompt_terminal_available() {
    [[ -r /dev/tty && -w /dev/tty ]]
}

# Runs whiptail on the terminal device. The dialog is drawn on /dev/tty and
# whiptail's result (written to stderr) is forwarded to stdout.
__whiptail() {
    env -u NEWT_COLORS_FILE NEWT_COLORS="$__prompt_whiptail_colors" \
        whiptail "$@" 2>&1 >/dev/tty </dev/tty
}

# Prints "<rows> <columns>" of the terminal, defaulting to 24x80.
__whiptail_screen_size() {
    local rows=24
    local columns=80
    local size

    if size="$(stty size </dev/tty 2>/dev/null)" && [[ "$size" =~ ^[1-9][0-9]*\ [1-9][0-9]*$ ]]; then
        rows="${size% *}"
        columns="${size#* }"
    fi

    printf '%d %d\n' "$rows" "$columns"
}

# __whiptail_dimensions <text> <extra_rows> <min_width> <min_content_width>
# Prints "<height> <width> <text_lines>" fitted to the text and terminal.
__whiptail_dimensions() {
    local text="$1"
    local extra_rows="$2"
    local min_content_width="$3"
    local rows
    local columns
    local line
    local longest="$min_content_width"
    local text_lines=0
    local width
    local height

    read -r rows columns < <(__whiptail_screen_size)

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((text_lines += 1))
        if (( ${#line} > longest )); then
            longest="${#line}"
        fi
    done <<<"$text"

    width=$((longest + 8))
    if (( width < 60 )); then
        width=60
    fi
    if (( width > columns - 4 )); then
        width=$((columns - 4))
    fi

    height=$((text_lines + extra_rows))
    if (( height > rows - 2 )); then
        height=$((rows - 2))
    fi

    printf '%d %d %d\n' "$height" "$width" "$text_lines"
}

# Drops decorative underline rows such as "-----" from a question.
__whiptail_clean_question() {
    local question="$1"
    local line
    local result=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^-+$ ]]; then
            continue
        fi

        result+="${result:+$'\n'}$line"
    done <<<"$question"

    printf '%s\n' "$result"
}

# Status text captured by show_status and rendered by the next choose_option.
# choose_option normally runs in a command substitution, so it cannot clear
# this; callers are expected to run show_status before every menu.
__prompt_status_text=""

##
# show_status <heading> <command...>
#
# Runs a status command and keeps its output for the next choose_option, which
# displays it inside the menu dialog. The command runs without colors and with
# stderr merged into its output, because the dialog hides the normal screen.
#
# Parameters:
#   heading    Heading text, may contain an underline line.
#   command    Command (and arguments) that prints the status.
#
# Returns:
#   The exit status of the status command.
#
show_status() {
    local heading="$1"
    local output
    local status=0

    shift

    output="$(NO_COLOR=1 FORCE_COLOR= "$@" 2>&1)" || status=$?
    __prompt_status_text="$(__whiptail_clean_question "$heading")"$'\n\n'"$output"

    if (( status != 0 )); then
        # The caller is expected to abort, so no dialog will show this text.
        printf '%s\n' "$output" >&2
    fi

    return "$status"
}

##
# pause_prompt
#
# Waits for Enter so action output stays readable before the next dialog
# replaces the screen.
#
pause_prompt() {
    local _

    printf 'Press Enter to continue...' >/dev/tty
    IFS= read -r _ </dev/tty || true
    printf '\n' >/dev/tty
}

##
# show_temporary_input_error <message>
#
# Displays an input error in a message box.
#
# Parameters:
#   message    Single-line error message to display.
#
show_temporary_input_error() {
    local message="$1"
    local height
    local width

    read -r height width _ < <(__whiptail_dimensions "$message" 6 0)

    __whiptail --title "Invalid input" --msgbox -- "$message" "$height" "$width" || true
}

##
# choose_option <question> <option...>
#
# Prompts for one option in a menu. Cancel or Esc finishes.
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

    local text
    local option
    local index=1
    local selected
    local status=0
    local height
    local width
    local text_lines
    local rows
    local list_height
    local longest=0
    local -a items=()

    text="$(__whiptail_clean_question "$1")"
    shift

    for option in "$@"; do
        items+=("$index" "$option")
        ((index += 1))
        if (( ${#option} + 6 > longest )); then
            longest=$((${#option} + 6))
        fi
    done

    read -r rows _ < <(__whiptail_screen_size)

    if [[ -n "$__prompt_status_text" ]]; then
        local combined="$__prompt_status_text"$'\n\n'"$text"
        local combined_lines

        read -r _ _ combined_lines < <(__whiptail_dimensions "$combined" 0 "$longest")

        if (( combined_lines + $# + 7 <= rows )); then
            text="$combined"
        else
            __whiptail --title "Status" --scrolltext --msgbox -- \
                "$__prompt_status_text" "$((rows - 2))" "$(__whiptail_dimensions "$__prompt_status_text" 0 "$longest" | cut -d' ' -f2)" || true
        fi
    fi

    read -r height width text_lines < <(__whiptail_dimensions "$text" 0 "$longest")

    list_height=$#
    if (( list_height > rows - text_lines - 8 )); then
        list_height=$((rows - text_lines - 8))
    fi
    if (( list_height < 1 )); then
        list_height=1
    fi
    height=$((text_lines + list_height + 7))

    selected="$(__whiptail --title "SysKit" --ok-button "Select" \
        --cancel-button "Finish" --menu -- "$text" \
        "$height" "$width" "$list_height" "${items[@]}")" || status=$?

    if (( status == 0 )); then
        printf '%s\n' "$selected"
    else
        printf 'X\n'
    fi
}

##
# confirm_action <question>
#
# Prompts for an explicit yes or no answer. The default answer is no.
#
# Parameters:
#   question    Confirmation question to display.
#
# Returns:
#   0 for Yes.
#   1 for No or Esc.
#   2 when arguments are invalid or no terminal is available.
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
    local height
    local width
    local status=0

    read -r height width _ < <(__whiptail_dimensions "$question" 6 0)

    __whiptail --title "Confirm" --defaultno --yesno -- "$question" \
        "$height" "$width" || status=$?

    case "$status" in
        0 | 1)
            return "$status"
            ;;
        255)
            return 1
            ;;
    esac

    return 2
}

##
# ask_text <question> [default_value]
#
# Prompts for non-empty text in an input box.
#
# Parameters:
#   question - Question displayed above the input field.
#   default_value - Optional value prefilled and used when the input is empty.
#
# Output:
#   Prints the entered text to standard output.
#
# Return:
#   0 - A non-empty text value was entered.
#   1 - Input is invalid or the dialog was cancelled.
#
ask_text() {
    local question="${1:-}"
    local default_value="${2-}"
    local input
    local status
    local height
    local width

    if (( $# < 1 || $# > 2 )); then
        printf 'ask_text accepts a question and optional default' >&2

        return 1
    fi

    if [[ -z "$question" ]]; then
        printf 'The text question must not be empty' >&2

        return 1
    fi

    if ! __prompt_terminal_available; then
        printf 'ask_text requires an interactive terminal.\n' >&2

        return 1
    fi

    read -r height width _ < <(__whiptail_dimensions "$question" 8 0)

    while true; do
        status=0
        input="$(__whiptail --title "SysKit" --inputbox -- "$question" \
            "$height" "$width" "$default_value")" || status=$?

        if (( status != 0 )); then
            return 1
        fi

        if [[ -z "$input" && -n "$default_value" ]]; then
            input="$default_value"
        fi

        if [[ -z "$input" ]]; then
            show_temporary_input_error 'A value is required.'

            continue
        fi

        printf '%s\n' "$input"

        return 0
    done
}
