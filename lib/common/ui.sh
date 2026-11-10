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
    local verb="$1"
    local -n __ui_offered_ref="$2"
    local -n __ui_labels_ref="$3"
    local -n __ui_search_ref="$4"
    local -n __ui_chosen_ref="$5"
    local item="${6:-module}"
    local -A __ui_selected=()
    local -A category_offered=()
    local -A category_selected=()
    local -a categories=()
    local -a selected_ids=()
    local -a menu_items=()
    local -a pick_ids=()
    local -a pick_items=()
    local id
    local category
    local label
    local done_label
    local pick_prompt
    local query
    local choice="Search..."

    if (( ${#__ui_offered_ref[@]} == 0 )); then
        ui_message "No ${item}s to $verb."

        return 1
    fi

    __ui_count_categories __ui_offered_ref category_offered categories

    while true; do
        selected_ids=("${!__ui_selected[@]}")
        __ui_count_categories selected_ids category_selected

        menu_items=(
            "Search..." "Find ${item}s by keyword"
            "All" "All ${item}s (${#__ui_offered_ref[@]})"
        )

        for category in "${categories[@]}"; do
            label="$(__ui_count "${category_offered[$category]}" "$item")"
            if [[ -v "category_selected[$category]" ]]; then
                label+=", ${category_selected[$category]} selected"
            fi

            menu_items+=("$category" "$label")
        done

        done_label="Select at least one $item first"
        if (( ${#__ui_selected[@]} > 0 )); then
            done_label="Continue with $(__ui_count "${#__ui_selected[@]}" "selected $item")"
        fi

        menu_items+=("Done" "$done_label")

        choice="$(ui_dialog --default-item "$choice" --cancel-button "Back" --menu \
            "Pick ${item}s to $verb. Selections are kept until Done." \
            "$UI_HEIGHT" "$UI_WIDTH" "$UI_LIST_HEIGHT" "${menu_items[@]}")" || return 1

        case "$choice" in
            "Search...")
                __ui_search_ids "$item" __ui_offered_ref __ui_search_ref pick_ids query || continue
                pick_prompt="Results for '$query' (${#pick_ids[@]}):"
                ;;
            All)
                pick_ids=("${__ui_offered_ref[@]}")
                pick_prompt="All ${item}s to $verb:"
                ;;
            Done)
                if (( ${#__ui_selected[@]} == 0 )); then
                    ui_message "Select at least one $item."

                    continue
                fi

                __ui_chosen_ref=()
                for id in "${__ui_offered_ref[@]}"; do
                    if [[ -v "__ui_selected[$id]" ]]; then
                        __ui_chosen_ref+=("$id")
                    fi
                done

                return 0
                ;;
            *)
                __ui_category_ids __ui_offered_ref "$choice" pick_ids
                pick_prompt="$choice ${item}s to $verb:"
                ;;
        esac

        pick_items=()
        for id in "${pick_ids[@]}"; do
            pick_items+=("$id" "${__ui_labels_ref[$id]:-}")
        done

        __ui_pick_items "$item" "$pick_prompt" __ui_selected "${pick_items[@]}"
    done
}
