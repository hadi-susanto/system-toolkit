#!/usr/bin/env bash
set -euo pipefail

source "$COMMON_LIB/common.sh"
source "$COMMON_LIB/checksum.sh"
source "$COMMON_LIB/resolver.sh"
source "$COMMON_LIB/ui.sh"
source "$SHELL_LIB/interface_loader.sh"
source "$SHELL_LIB/modules.sh"

readonly -a __SHELL_UI_COMMANDS=(install uninstall activate deactivate status)
readonly -A __SHELL_UI_COMMAND_LABELS=(
    [install]="Install modules"
    [uninstall]="Uninstall installed modules"
    [activate]="Activate the module loader"
    [deactivate]="Deactivate the module loader"
    [status]="Show the module and loader report"
)

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
# __module_label <canonical_id>
#
# Describes the installed state of a shell module for the module checklists.
#
# Output:
#   Prints the label.
#
# Returns:
#   1 when the module is not installed.
#
__module_label() {
    local canonical_id="$1"
    local source
    local target
    local checksum_status=0

    if ! module_installed "$canonical_id"; then
        printf 'not installed\n'

        return 1
    fi

    if ! target="$(installed_module_path "$canonical_id" 2>/dev/null)" ||
        ! source="$(module_source_path "$canonical_id" 2>/dev/null)"; then
        printf 'installed, unknown version\n'

        return 0
    fi

    checksums_match "$source" "$target" 2>/dev/null || checksum_status=$?

    case "$checksum_status" in
        0)
            printf 'installed\n'
            ;;
        1)
            printf 'installed, update available\n'
            ;;
        *)
            printf 'installed, unknown version\n'
            ;;
    esac
}

##
# __detect_modules <supported_name> <installed_name> <labels_name> <search_name>
#
# Lists the modules supported by the loaded shell interface with their labels
# and search texts (canonical ID and aliases), and the installed subset.
#
# Returns:
#   1 when the shell modules cannot be listed.
#
__detect_modules() {
    local -n supported_ref="$1"
    local -n installed_ref="$2"
    local -n labels_ref="$3"
    local -n search_ref="$4"
    local -a all_modules=()
    local -a aliases=()
    local canonical_id
    local label

    supported_ref=()
    installed_ref=()
    labels_ref=()
    search_ref=()

    list_shell_modules all_modules || return 1

    for canonical_id in "${all_modules[@]}"; do
        support_module "$canonical_id" || continue

        supported_ref+=("$canonical_id")
        resolve_module_aliases "$canonical_id" aliases
        search_ref["$canonical_id"]="$canonical_id ${aliases[*]}"

        if label="$(__module_label "$canonical_id")"; then
            installed_ref+=("$canonical_id")
        fi

        labels_ref["$canonical_id"]="$label"
    done
}

##
# __choose_command <shell> <installed_count> <supported_count> <command_name>
#
# Shows the welcome menu with the shell and loader state and stores the
# selected command.
#
# Returns:
#   1 when the menu was cancelled.
#
__choose_command() {
    local shell="$1"
    local installed_count="$2"
    local supported_count="$3"
    local -n command_ref="$4"
    local -a menu_items=()
    local menu_command
    local shell_state="installed"
    local loader_state="inactive"

    if ! shell_installed "$shell"; then
        shell_state="not installed"
    fi

    if loader_active; then
        loader_state="active"
    fi

    for menu_command in "${__SHELL_UI_COMMANDS[@]}"; do
        menu_items+=("$menu_command" "${__SHELL_UI_COMMAND_LABELS[$menu_command]}")
    done

    command_ref="$(ui_dialog --cancel-button "Quit" --menu \
        "Welcome to SysKit shell integration for $shell.\n\n$shell: $shell_state, loader: $loader_state, modules installed: $installed_count of $supported_count\n\nChoose what to do:" \
        "$UI_HEIGHT" "$UI_WIDTH" "${#__SHELL_UI_COMMANDS[@]}" "${menu_items[@]}")" || return 1
}

##
# __choose_options <shell> <command> <options_name>
#
# Shows the option checklist of a command, if it has options, and stores the
# selected command-line options.
#
# Returns:
#   1 when the checklist was cancelled.
#
__choose_options() {
    local shell="$1"
    local command="$2"
    local options_name="$3"
    local -a checklist_items=()

    case "$command" in
        install)
            checklist_items=(force "Reinstall installed modules and bypass failed dependency checks" OFF)
            ;;
        uninstall)
            checklist_items=(force "Attempt removal even when a module is not detected as installed" OFF)
            ;;
        activate)
            checklist_items=(force "Recreate an active loader and refresh its startup-file block" OFF)
            ;;
        deactivate)
            checklist_items=(force "Attempt removal even when the loader is inactive" OFF)
            ;;
    esac

    ui_choose_options "syskit-$shell $command" "$options_name" "${checklist_items[@]}"
}

main() {
    local shell="${1:-}"
    local -A options=()
    local -a args=()
    local -a supported=()
    local -a installed=()
    local -A labels=()
    local -A search=()
    local -a modules=()
    local -a command_options=()
    local command=""
    local status=0

    if (( $# > 0 )); then
        shift
    fi

    __parse_args options args "$@" || status=$?
    if (( status == 0 )); then
        __validate_options args || status=$?
    fi

    if (( status != 0 )); then
        bash "$SHELL_COMMAND/help.sh" "$shell" ui >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        exec bash "$SHELL_COMMAND/help.sh" "$shell" ui
    fi

    load_shell_interface "$shell" \
        "support_module" \
        "module_installed" \
        "installed_module_path" \
        "module_source_path" \
        "loader_active" || return 1

    ui_init "SysKit $shell integration" || return 2
    __detect_modules supported installed labels search || return 1

    while true; do
        __choose_command "$shell" "${#installed[@]}" "${#supported[@]}" command || return 0

        modules=()
        case "$command" in
            install)
                ui_choose_modules install supported labels search modules || continue
                ;;
            uninstall)
                if (( ${#installed[@]} == 0 )); then
                    ui_message "No $shell modules are installed."

                    continue
                fi

                ui_choose_modules uninstall installed labels search modules || continue
                ;;
        esac

        __choose_options "$shell" "$command" command_options || continue
        ui_confirm "syskit-$shell" "$command" "${command_options[@]}" "${modules[@]}" || continue

        clear >/dev/tty 2>/dev/null || true
        exec bash "$SHELL_COMMAND/main.sh" "$shell" "$command" "${command_options[@]}" "${modules[@]}"
    done
}

main "$@"
