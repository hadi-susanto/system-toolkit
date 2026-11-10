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
    local __ui_command_label="$1"
    local -n __ui_options_ref="$2"
    shift 2

    local __ui_output
    local __ui_option

    __ui_options_ref=()

    if (( $# == 0 )); then
        return 0
    fi

    __ui_output="$(ui_dialog --separate-output --checklist "Options for $__ui_command_label:" \
        15 "$UI_WIDTH" $(( $# / 3 )) "$@")" || return 1

    while IFS= read -r __ui_option; do
        if [[ -n "$__ui_option" ]]; then
            __ui_options_ref+=("--$__ui_option")
        fi
    done <<<"$__ui_output"
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

# Prints "<count> <noun>", pluralizing the noun with "s" unless count is 1.
__ui_count() {
    local count="$1"
    local noun="$2"

    if (( count == 1 )); then
        printf '1 %s\n' "$noun"

        return 0
    fi

    printf '%d %ss\n' "$count" "$noun"
}

##
# __ui_count_categories <ids_name> <counts_name> [categories_name]
#
# Counts the IDs in <category>/<name> form per category, optionally listing
# the categories in first-seen order. Other IDs are ignored.
#
__ui_count_categories() {
    local -n __ui_cc_ids_ref="$1"
    local -n __ui_cc_counts_ref="$2"
    local categories_name="${3:-}"
    local -a found=()
    local id
    local category

    __ui_cc_counts_ref=()

    for id in "${__ui_cc_ids_ref[@]}"; do
        [[ "$id" == */* ]] || continue

        category="${id%%/*}"
        if [[ ! -v "__ui_cc_counts_ref[$category]" ]]; then
            found+=("$category")
        fi

        __ui_cc_counts_ref["$category"]=$(( ${__ui_cc_counts_ref[$category]:-0} + 1 ))
    done

    if [[ -n "$categories_name" ]]; then
        local -n __ui_cc_categories_ref="$categories_name"

        __ui_cc_categories_ref=("${found[@]}")
    fi
}

##
# __ui_category_ids <ids_name> <category> <matches_name>
#
# Lists the IDs of one category, in order.
#
__ui_category_ids() {
    local -n __ui_ci_ids_ref="$1"
    local category="$2"
    local -n __ui_ci_matches_ref="$3"
    local id

    __ui_ci_matches_ref=()

    for id in "${__ui_ci_ids_ref[@]}"; do
        if [[ "$id" == "$category/"* ]]; then
            __ui_ci_matches_ref+=("$id")
        fi
    done
}

##
# __ui_search_ids <item> <ids_name> <search_name> <matches_name> <query_name>
#
# Asks for a search query and lists the IDs whose search text matches it.
#
# Returns:
#   1 when the search was cancelled, the query is blank, or nothing matches
#   (after telling the user).
#
__ui_search_ids() {
    local item="$1"
    local -n __ui_si_ids_ref="$2"
    local -n __ui_si_search_ref="$3"
    local -n __ui_si_matches_ref="$4"
    local -n __ui_si_query_ref="$5"
    local id

    __ui_si_matches_ref=()

    __ui_si_query_ref="$(ui_dialog --inputbox "Search ${item}s (every word must match):" \
        10 "$UI_WIDTH")" || return 1
    [[ -n "${__ui_si_query_ref//[[:space:]]/}" ]] || return 1

    for id in "${__ui_si_ids_ref[@]}"; do
        if __ui_text_matches "$__ui_si_query_ref" "${__ui_si_search_ref[$id]:-$id}"; then
            __ui_si_matches_ref+=("$id")
        fi
    done

    if (( ${#__ui_si_matches_ref[@]} == 0 )); then
        ui_message "No ${item}s match '$__ui_si_query_ref'."

        return 1
    fi
}

##
# __ui_pick_items <item> <prompt> <selected_name> [<id> <label>]...
#
# Shows a checklist of the given items, checked when already selected, and
# updates the selection set for them. Cancel leaves the selection unchanged.
#
# Parameters:
#   item             Singular item noun, such as "module".
#   prompt           Checklist text.
#   selected_name    Name of the associative array holding the selection
#                    (ID -> 1).
#
__ui_pick_items() {
    local item="$1"
    local prompt="$2"
    local -n __ui_pick_selected_ref="$3"
    shift 3

    local -a checklist_items=()
    local -a ids=()
    local -A checked=()
    local id
    local state
    local output

    while (( $# >= 2 )); do
        id="$1"
        state="OFF"
        if [[ -v "__ui_pick_selected_ref[$id]" ]]; then
            state="ON"
        fi

        checklist_items+=("$id" "$2" "$state")
        ids+=("$id")
        shift 2
    done

    output="$(ui_dialog --separate-output --checklist "$prompt\nSpace toggles the highlighted $item, Enter confirms." \
        "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${checklist_items[@]}")" || return 0

    while IFS= read -r id; do
        if [[ -n "$id" ]]; then
            checked["$id"]=1
        fi
    done <<<"$output"

    # Only the shown items change, so unchecking one removes it from the selection.
    for id in "${ids[@]}"; do
        if [[ -v "checked[$id]" ]]; then
            __ui_pick_selected_ref["$id"]=1
        else
            unset "__ui_pick_selected_ref[$id]"
        fi
    done
}

##
# ui_choose_items <verb> <offered_name> <labels_name> <search_name> <selected_name> [item]
#
# Shows the item menu (search, all items, one entry per category, done) and
# stores the selected IDs in offered order. IDs in <category>/<name> form are
# grouped by category; other IDs only appear under search and all. Selections
# are kept across the menu entries until Done, which requires at least one
# item.
#
# Parameters:
#   verb             Action shown in the dialog texts, such as "install".
#   offered_name     Name of the indexed array of offered IDs, in display
#                    order.
#   labels_name      Name of the associative array mapping an ID to its
#                    checklist label.
#   search_name      Name of the associative array mapping an ID to the text
#                    searched; the ID itself when absent.
#   selected_name    Name of the indexed array that receives the selection.
#   item             Singular item noun used in the texts (default: module).
#
# Returns:
#   1 when the menu was cancelled or no item is offered.
#
ui_choose_items() {
    local __ui_verb="$1"
    local -n __ui_offered_ref="$2"
    local -n __ui_labels_ref="$3"
    local -n __ui_search_ref="$4"
    local -n __ui_chosen_ref="$5"
    local __ui_item="${6:-module}"
    local -A __ui_selected=()
    local -A __ui_category_offered=()
    local -A __ui_category_selected=()
    local -a __ui_categories=()
    local -a __ui_selected_ids=()
    local -a __ui_menu_items=()
    local -a __ui_pick_ids=()
    local -a __ui_pick_items=()
    local __ui_id
    local __ui_category
    local __ui_label
    local __ui_done_label
    local __ui_pick_prompt
    local __ui_query
    local __ui_choice="Search..."

    if (( ${#__ui_offered_ref[@]} == 0 )); then
        ui_message "No ${__ui_item}s to $__ui_verb."

        return 1
    fi

    __ui_count_categories __ui_offered_ref __ui_category_offered __ui_categories

    while true; do
        __ui_selected_ids=("${!__ui_selected[@]}")
        __ui_count_categories __ui_selected_ids __ui_category_selected

        __ui_menu_items=(
            "Search..." "Find ${__ui_item}s by keyword"
            "All" "All ${__ui_item}s (${#__ui_offered_ref[@]})"
        )

        for __ui_category in "${__ui_categories[@]}"; do
            __ui_label="$(__ui_count "${__ui_category_offered[$__ui_category]}" "$__ui_item")"
            if [[ -v "__ui_category_selected[$__ui_category]" ]]; then
                __ui_label+=", ${__ui_category_selected[$__ui_category]} selected"
            fi

            __ui_menu_items+=("$__ui_category" "$__ui_label")
        done

        __ui_done_label="Select at least one $__ui_item first"
        if (( ${#__ui_selected[@]} > 0 )); then
            __ui_done_label="Continue with $(__ui_count "${#__ui_selected[@]}" "selected $__ui_item")"
        fi

        __ui_menu_items+=("Done" "$__ui_done_label")

        __ui_choice="$(ui_dialog --default-item "$__ui_choice" --cancel-button "Back" --menu \
            "Pick ${__ui_item}s to $__ui_verb. Selections are kept until Done." \
            "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${__ui_menu_items[@]}")" || return 1

        case "$__ui_choice" in
            "Search...")
                __ui_search_ids "$__ui_item" __ui_offered_ref __ui_search_ref __ui_pick_ids __ui_query || continue
                __ui_pick_prompt="Results for '$__ui_query' (${#__ui_pick_ids[@]}):"
                ;;
            All)
                __ui_pick_ids=("${__ui_offered_ref[@]}")
                __ui_pick_prompt="All ${__ui_item}s to $__ui_verb:"
                ;;
            Done)
                if (( ${#__ui_selected[@]} == 0 )); then
                    ui_message "Select at least one $__ui_item."

                    continue
                fi

                __ui_chosen_ref=()
                for __ui_id in "${__ui_offered_ref[@]}"; do
                    if [[ -v "__ui_selected[$__ui_id]" ]]; then
                        __ui_chosen_ref+=("$__ui_id")
                    fi
                done

                return 0
                ;;
            *)
                __ui_category_ids __ui_offered_ref "$__ui_choice" __ui_pick_ids
                __ui_pick_prompt="$__ui_choice ${__ui_item}s to $__ui_verb:"
                ;;
        esac

        __ui_pick_items=()
        for __ui_id in "${__ui_pick_ids[@]}"; do
            __ui_pick_items+=("$__ui_id" "${__ui_labels_ref[$__ui_id]:-}")
        done

        __ui_pick_items "$__ui_item" "$__ui_pick_prompt" __ui_selected "${__ui_pick_items[@]}"
    done
}

##
# ui_choose_item <verb> <offered_name> <labels_name> <search_name> <chosen_name> <item> <cancel_label> [<tag> <label>]...
#
# Shows the item menu (search, all items, one entry per category, and any
# extra entries) and stores the one item picked from the matching list. An
# extra entry is stored as its tag instead; its tag must not collide with an
# offered category, "Search...", or "All".
#
# Parameters:
#   verb            Action shown in the dialog texts, such as "configure".
#   offered_name    Name of the indexed array of offered IDs, in display
#                   order.
#   labels_name     Name of the associative array mapping an ID to its menu
#                   label.
#   search_name     Name of the associative array mapping an ID to the text
#                   searched; the ID itself when absent.
#   chosen_name     Name of the variable that receives the ID or extra tag.
#   item            Singular item noun used in the texts, such as "module".
#   cancel_label    Label of the cancel button, such as "Quit" or "Back".
#   tag, label      Extra top-level menu entries.
#
# Returns:
#   1 when the menu was cancelled or nothing is offered.
#
ui_choose_item() {
    local __ui_verb="$1"
    local -n __ui_one_offered_ref="$2"
    local -n __ui_one_labels_ref="$3"
    local -n __ui_one_search_ref="$4"
    local -n __ui_one_chosen_ref="$5"
    local __ui_item="$6"
    local __ui_cancel_label="$7"
    shift 7

    local -a __ui_extra_items=("$@")
    local -A __ui_extra_tags=()
    local -A __ui_category_offered=()
    local -a __ui_categories=()
    local -a __ui_menu_items=()
    local -a __ui_pick_ids=()
    local -a __ui_pick_items=()
    local __ui_id
    local __ui_index
    local __ui_category
    local __ui_pick_prompt
    local __ui_query
    local __ui_picked
    local __ui_choice="Search..."

    if (( ${#__ui_one_offered_ref[@]} == 0 && ${#__ui_extra_items[@]} == 0 )); then
        ui_message "No ${__ui_item}s to $__ui_verb."

        return 1
    fi

    for (( __ui_index = 0; __ui_index < ${#__ui_extra_items[@]}; __ui_index += 2 )); do
        __ui_extra_tags["${__ui_extra_items[__ui_index]}"]=1
    done

    __ui_count_categories __ui_one_offered_ref __ui_category_offered __ui_categories

    while true; do
        __ui_menu_items=(
            "Search..." "Find ${__ui_item}s by keyword"
            "All" "All ${__ui_item}s (${#__ui_one_offered_ref[@]})"
        )

        for __ui_category in "${__ui_categories[@]}"; do
            __ui_menu_items+=("$__ui_category" "$(__ui_count "${__ui_category_offered[$__ui_category]}" "$__ui_item")")
        done

        __ui_menu_items+=("${__ui_extra_items[@]}")

        __ui_choice="$(ui_dialog --default-item "$__ui_choice" --cancel-button "$__ui_cancel_label" --menu \
            "Pick a $__ui_item to $__ui_verb by category or search." \
            "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${__ui_menu_items[@]}")" || return 1

        if [[ -v "__ui_extra_tags[$__ui_choice]" ]]; then
            __ui_one_chosen_ref="$__ui_choice"

            return 0
        fi

        case "$__ui_choice" in
            "Search...")
                __ui_search_ids "$__ui_item" __ui_one_offered_ref __ui_one_search_ref __ui_pick_ids __ui_query || continue
                __ui_pick_prompt="Results for '$__ui_query' (${#__ui_pick_ids[@]}):"
                ;;
            All)
                __ui_pick_ids=("${__ui_one_offered_ref[@]}")
                __ui_pick_prompt="All ${__ui_item}s:"
                ;;
            *)
                __ui_category_ids __ui_one_offered_ref "$__ui_choice" __ui_pick_ids
                __ui_pick_prompt="$__ui_choice ${__ui_item}s:"
                ;;
        esac

        __ui_pick_items=()
        for __ui_id in "${__ui_pick_ids[@]}"; do
            __ui_pick_items+=("$__ui_id" "${__ui_one_labels_ref[$__ui_id]:-}")
        done

        __ui_picked="$(ui_dialog --cancel-button "Back" --menu "$__ui_pick_prompt\nPick a $__ui_item to $__ui_verb." \
            "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${__ui_pick_items[@]}")" || continue

        __ui_one_chosen_ref="$__ui_picked"

        return 0
    done
}

##
# ui_show_text <text>
#
# Shows text in a scrollable message box sized to the terminal.
#
ui_show_text() {
    ui_dialog --scrolltext --msgbox -- "$1" "$UI_HEIGHT" "$UI_WIDTH" || true
}

##
# ui_pause
#
# Waits for Enter on the terminal so output printed between dialogs stays
# readable before the next dialog covers it.
#
ui_pause() {
    local _

    printf '\nPress Enter to return to %s...' "$UI_TITLE" >/dev/tty
    IFS= read -r _ </dev/tty || true
}
