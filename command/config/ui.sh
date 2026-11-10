#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/resolver.sh"
source "$COMMON_LIB/ui.sh"
source "$CONFIG_LIB/metadata.sh"

readonly __CONFIG_UI_STATUS_ALL="Status (all)"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [HELP]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -h | --help)
                options_ref[HELP]=1
                ;;
            -*)
                log_error "Unknown ui option: $1"

                return 2
                ;;
            *)
                args_ref+=("$1")
                ;;
        esac

        shift
    done
}

__validate_options() {
    local args_name="$1"
    local -n args_ref="$args_name"

    if (( ${#args_ref[@]} > 0 )); then
        log_error "The ui command does not accept arguments: ${args_ref[*]}"

        return 2
    fi
}

##
# __load_catalog <modules_name> <names_name> <descriptions_name> <labels_name> <search_name>
#
# Lists the configuration modules with their metadata, menu labels, and search
# texts (canonical ID, name, description, and aliases). A module with invalid
# metadata stays listed under its canonical ID.
#
# Returns:
#   1 when the modules cannot be listed.
#
__load_catalog() {
    local modules_name="$1"
    local -n catalog_modules_ref="$modules_name"
    local -n names_ref="$2"
    local -n descriptions_ref="$3"
    local -n labels_ref="$4"
    local -n search_ref="$5"
    local -A module_metadata=()
    local -a aliases=()
    local canonical_id

    # Pass the caller's name: list_config_modules declares its own modules_ref.
    list_config_modules "$modules_name" || return 1

    for canonical_id in "${catalog_modules_ref[@]}"; do
        names_ref["$canonical_id"]="$canonical_id"
        descriptions_ref["$canonical_id"]="(invalid metadata)"

        if parse_config_metadata "$canonical_id" module_metadata 2>/dev/null; then
            names_ref["$canonical_id"]="${module_metadata[NAME]}"
            descriptions_ref["$canonical_id"]="${module_metadata[DESCRIPTION]}"
        fi

        resolve_module_aliases "$canonical_id" aliases
        labels_ref["$canonical_id"]="${names_ref[$canonical_id]}: ${descriptions_ref[$canonical_id]}"
        search_ref["$canonical_id"]="$canonical_id ${names_ref[$canonical_id]} ${descriptions_ref[$canonical_id]} ${aliases[*]}"
    done
}

##
# __show_status <status_arg>...
#
# Runs the configuration status command without colors and shows its output
# in a scrollable dialog, including when the status command fails.
#
__show_status() {
    local output
    local status=0

    output="$(NO_COLOR=1 FORCE_COLOR='' bash "$CONFIG_COMMAND/status.sh" "$@" 2>&1)" || status=$?

    if (( status != 0 )); then
        output="Status failed with status $status.\n\n$output"
    fi

    ui_show_text "$output"
}

##
# __configure_module <canonical_id> <force>
#
# Runs the module's interactive configuration on the terminal, then waits for
# Enter so its output stays readable.
#
__configure_module() {
    local canonical_id="$1"
    local force="$2"
    local -a configure_args=()

    if (( force )); then
        configure_args+=("--force")
    fi

    clear >/dev/tty 2>/dev/null || true
    bash "$CONFIG_COMMAND/configure.sh" "${configure_args[@]}" "$canonical_id" || true
    ui_pause
}

##
# __module_actions <canonical_id> <name> <description>
#
# Shows the action menu of one module until Back.
#
__module_actions() {
    local canonical_id="$1"
    local name="$2"
    local description="$3"
    local action="configure"

    while true; do
        action="$(ui_dialog --default-item "$action" --cancel-button "Back" --menu \
            "$name [$canonical_id]\n\n$description" \
            16 "$UI_WIDTH" 3 \
            configure "Configure" \
            force "Configure with --force" \
            status "Show status")" || return 0

        case "$action" in
            configure)
                __configure_module "$canonical_id" 0
                ;;
            force)
                __configure_module "$canonical_id" 1
                ;;
            status)
                __show_status "$canonical_id"
                ;;
        esac
    done
}

main() {
    local -A options=()
    local -a args=()
    local -a modules=()
    local -A names=()
    local -A descriptions=()
    local -A labels=()
    local -A search=()
    local choice=""
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status == 0 )); then
        __validate_options args || status=$?
    fi

    if (( status != 0 )); then
        bash "$CONFIG_COMMAND/help.sh" ui >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        exec bash "$CONFIG_COMMAND/help.sh" ui
    fi

    ui_init "SysKit configuration" || return 2
    __load_catalog modules names descriptions labels search || return 1

    while true; do
        ui_choose_item configure modules labels search choice module "Quit" \
            "$__CONFIG_UI_STATUS_ALL" "Show the status of every module" || return 0

        if [[ "$choice" == "$__CONFIG_UI_STATUS_ALL" ]]; then
            __show_status --all

            continue
        fi

        __module_actions "$choice" "${names[$choice]}" "${descriptions[$choice]}"
    done
}

main "$@"
