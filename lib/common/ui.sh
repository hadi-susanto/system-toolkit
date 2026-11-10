if (( ${__SYSKIT_UI_LOADED:-0} )); then
    return 0
fi

readonly __SYSKIT_UI_LOADED=1

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/whiptail-theme.sh"

readonly __UI_MIN_LINES=24
readonly __UI_MIN_COLUMNS=80
readonly __UI_MAX_WIDTH=100

# Dialog title and geometry shared by every dialog, set by ui_init.
UI_TITLE=""
UI_HEIGHT=0
UI_WIDTH=0
UI_LIST_HEIGHT=0

##
# ui_terminal_usable
#
# Checks that whiptail is installed and the controlling terminal can be used.
#
# Returns:
#   1 when whiptail or the terminal is unavailable.
#
ui_terminal_usable() {
    command -v whiptail >/dev/null 2>&1 &&
        [[ -r /dev/tty && -w /dev/tty ]] &&
        { : </dev/tty; } 2>/dev/null &&
        { : >/dev/tty; } 2>/dev/null
}

##
# ui_init <title>
#
# Checks the terminal and sizes the dialogs from it.
#
# Parameters:
#   title    Title shown on every dialog.
#
# Returns:
#   1 when whiptail or the terminal is unavailable, or the terminal is smaller
#   than the supported minimum.
#
ui_init() {
    local title="$1"
    local size
    local lines
    local columns

    if ! ui_terminal_usable; then
        log_error "The UI needs whiptail and an interactive terminal (sudo apt install whiptail)"

        return 1
    fi

    size="$(stty size </dev/tty 2>/dev/null)" || size=""
    if [[ ! "$size" =~ ^([0-9]+)\ ([0-9]+)$ ]]; then
        log_error "Unable to read the terminal size"

        return 1
    fi

    lines="${BASH_REMATCH[1]}"
    columns="${BASH_REMATCH[2]}"

    if (( lines < __UI_MIN_LINES || columns < __UI_MIN_COLUMNS )); then
        log_error "The UI needs a terminal of at least ${__UI_MIN_COLUMNS}x${__UI_MIN_LINES} (current: ${columns}x${lines})"

        return 1
    fi

    UI_TITLE="$title"
    UI_HEIGHT=$(( lines - 4 ))
    UI_WIDTH=$(( columns - 4 < __UI_MAX_WIDTH ? columns - 4 : __UI_MAX_WIDTH ))
    UI_LIST_HEIGHT=$(( UI_HEIGHT - 8 ))
}

##
# ui_dialog <whiptail_arg>...
#
# Runs a themed whiptail dialog, titled UI_TITLE, on the controlling terminal.
#
# Output:
#   Prints the dialog result.
#
# Returns:
#   whiptail's status: 1 for Cancel or No, 255 for Esc.
#
ui_dialog() {
    env -u NEWT_COLORS_FILE NEWT_COLORS="$SYSKIT_WHIPTAIL_COLORS" \
        whiptail --title "$UI_TITLE" "$@" 3>&1 1>&2 2>&3 </dev/tty >/dev/tty
}

##
# ui_message <text>
#
# Shows a message box and waits for OK.
#
ui_message() {
    ui_dialog --msgbox "$1" 10 60 || true
}

##
# ui_confirm <word>...
#
# Asks whether to run the command line made of the given words.
#
# Returns:
#   1 when the user declined or cancelled.
#
ui_confirm() {
    ui_dialog --yes-button "Run" --no-button "Back" --yesno \
        "Run this command?\n\n  $*" 12 "$UI_WIDTH"
}

##
# ui_choose_options <command_label> <options_name> [<tag> <description> <state>]...
#
# Shows an option checklist and stores the checked options as "--<tag>". Tags
# have no leading dashes so whiptail does not read them as its own options.
# Without option triples, nothing is shown and no option is stored.
#
# Parameters:
#   command_label    Command shown in the checklist text.
#   options_name     Name of the indexed array that receives the options.
#   tag              Option name without leading dashes.
#   description      Option description.
#   state            Initial state: ON or OFF.
#
# Returns:
#   1 when the checklist was cancelled.
#
ui_choose_options() {
    local command_label="$1"
    local -n __ui_options_ref="$2"
    shift 2

    local output
    local option

    __ui_options_ref=()

    if (( $# == 0 )); then
        return 0
    fi

    output="$(ui_dialog --separate-output --checklist "Options for $command_label:" \
        15 "$UI_WIDTH" $(( $# / 3 )) "$@")" || return 1

    while IFS= read -r option; do
        if [[ -n "$option" ]]; then
            __ui_options_ref+=("--$option")
        fi
    done <<<"$output"
}

##
# __ui_text_matches <query> <text>
#
# Checks whether every word of the query appears, case-insensitively, in the
# text.
#
# Returns:
#   1 when a word does not match.
#
__ui_text_matches() {
    local query="${1,,}"
    local text="${2,,}"
    local -a words=()
    local word

    read -ra words <<<"$query"
    for word in "${words[@]}"; do
        [[ "$text" == *"$word"* ]] || return 1
    done
}

##
# __ui_pick_modules <prompt> <selected_name> [<canonical_id> <label>]...
#
# Shows a checklist of the given modules, checked when already selected, and
# updates the selection set for them. Cancel leaves the selection unchanged.
#
# Parameters:
#   prompt           Checklist text.
#   selected_name    Name of the associative array holding the selection
#                    (canonical ID -> 1).
#
__ui_pick_modules() {
    local prompt="$1"
    local -n __ui_pick_selected_ref="$2"
    shift 2

    local -a checklist_items=()
    local -a canonical_ids=()
    local -A checked=()
    local canonical_id
    local state
    local output

    while (( $# >= 2 )); do
        canonical_id="$1"
        state="OFF"
        if [[ -v "__ui_pick_selected_ref[$canonical_id]" ]]; then
            state="ON"
        fi

        checklist_items+=("$canonical_id" "$2" "$state")
        canonical_ids+=("$canonical_id")
        shift 2
    done

    output="$(ui_dialog --separate-output --checklist "$prompt\nSpace toggles a module, Enter confirms." \
        "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${checklist_items[@]}")" || return 0

    while IFS= read -r canonical_id; do
        if [[ -n "$canonical_id" ]]; then
            checked["$canonical_id"]=1
        fi
    done <<<"$output"

    # Only the shown modules change, so unchecking one removes it from the selection.
    for canonical_id in "${canonical_ids[@]}"; do
        if [[ -v "checked[$canonical_id]" ]]; then
            __ui_pick_selected_ref["$canonical_id"]=1
        else
            unset "__ui_pick_selected_ref[$canonical_id]"
        fi
    done
}

##
# ui_choose_modules <verb> <offered_name> <labels_name> <search_name> <modules_name>
#
# Shows the module menu (search, all modules, one entry per category, done)
# and stores the selected canonical IDs in offered order. Selections are kept
# across the menu entries until Done, which requires at least one module.
#
# Parameters:
#   verb            Action shown in the dialog texts, such as "install".
#   offered_name    Name of the indexed array of offered canonical IDs, in
#                   display order.
#   labels_name     Name of the associative array mapping a canonical ID to
#                   its checklist label.
#   search_name     Name of the associative array mapping a canonical ID to
#                   the text searched; the ID itself when absent.
#   modules_name    Name of the indexed array that receives the selection.
#
# Returns:
#   1 when the menu was cancelled or no module is offered.
#
ui_choose_modules() {
    local verb="$1"
    local -n __ui_offered_ref="$2"
    local -n __ui_labels_ref="$3"
    local -n __ui_search_ref="$4"
    local -n __ui_modules_ref="$5"
    local -A __ui_selected=()
    local -A category_offered=()
    local -A category_selected=()
    local -a categories=()
    local -a menu_items=()
    local -a pick_ids=()
    local -a pick_items=()
    local canonical_id
    local category
    local label
    local done_label
    local pick_prompt
    local query
    local choice="Search..."

    if (( ${#__ui_offered_ref[@]} == 0 )); then
        ui_message "No modules to $verb."

        return 1
    fi

    for canonical_id in "${__ui_offered_ref[@]}"; do
        category="${canonical_id%%/*}"
        if [[ ! -v "category_offered[$category]" ]]; then
            categories+=("$category")
        fi

        category_offered["$category"]=$(( ${category_offered[$category]:-0} + 1 ))
    done

    while true; do
        category_selected=()
        for canonical_id in "${!__ui_selected[@]}"; do
            category="${canonical_id%%/*}"
            category_selected["$category"]=$(( ${category_selected[$category]:-0} + 1 ))
        done

        menu_items=(
            "Search..." "Find modules by keyword"
            "All" "All modules (${#__ui_offered_ref[@]})"
        )

        for category in "${categories[@]}"; do
            label="${category_offered[$category]} modules"
            if [[ -v "category_selected[$category]" ]]; then
                label+=", ${category_selected[$category]} selected"
            fi

            menu_items+=("$category" "$label")
        done

        done_label="Select at least one module first"
        if (( ${#__ui_selected[@]} > 0 )); then
            done_label="Continue with ${#__ui_selected[@]} selected module(s)"
        fi

        menu_items+=("Done" "$done_label")

        choice="$(ui_dialog --default-item "$choice" --cancel-button "Back" --menu \
            "Pick modules to $verb by category or search. Selections are kept until Done." \
            "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${menu_items[@]}")" || return 1

        pick_ids=()
        case "$choice" in
            "Search...")
                query="$(ui_dialog --inputbox "Search modules (every word must match):" \
                    10 "$UI_WIDTH")" || continue
                [[ -n "${query//[[:space:]]/}" ]] || continue

                for canonical_id in "${__ui_offered_ref[@]}"; do
                    if __ui_text_matches "$query" "${__ui_search_ref[$canonical_id]:-$canonical_id}"; then
                        pick_ids+=("$canonical_id")
                    fi
                done

                if (( ${#pick_ids[@]} == 0 )); then
                    ui_message "No modules match '$query'."

                    continue
                fi

                pick_prompt="Results for '$query' (${#pick_ids[@]}):"
                ;;
            All)
                pick_ids=("${__ui_offered_ref[@]}")
                pick_prompt="All modules to $verb:"
                ;;
            Done)
                if (( ${#__ui_selected[@]} == 0 )); then
                    ui_message "Select at least one module."

                    continue
                fi

                __ui_modules_ref=()
                for canonical_id in "${__ui_offered_ref[@]}"; do
                    if [[ -v "__ui_selected[$canonical_id]" ]]; then
                        __ui_modules_ref+=("$canonical_id")
                    fi
                done

                return 0
                ;;
            *)
                for canonical_id in "${__ui_offered_ref[@]}"; do
                    if [[ "${canonical_id%%/*}" == "$choice" ]]; then
                        pick_ids+=("$canonical_id")
                    fi
                done

                pick_prompt="$choice modules to $verb:"
                ;;
        esac

        pick_items=()
        for canonical_id in "${pick_ids[@]}"; do
            pick_items+=("$canonical_id" "${__ui_labels_ref[$canonical_id]:-}")
        done

        __ui_pick_modules "$pick_prompt" __ui_selected "${pick_items[@]}"
    done
}
